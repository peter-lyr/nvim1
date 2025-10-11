import re
import matplotlib.pyplot as plt


# --------------------------
# 1. 解析 map.txt 获取主section数据
# --------------------------
def parse_map_file(map_path):
    # 正则匹配主/子section
    main_section_pattern = re.compile(
        r"^(\.\w+)\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)", re.IGNORECASE
    )
    single_sub_pattern = re.compile(
        r"^\s+(\.\w+(\.\w+)*)\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)", re.IGNORECASE
    )
    sub_name_pattern = re.compile(r"^\s+(\.\w+(\.\w+)*)\s*$", re.IGNORECASE)
    sub_addr_pattern = re.compile(
        r"^\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)", re.IGNORECASE
    )

    main_sections = []
    current_main = None
    with open(map_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_stripped = line.strip("\n").rstrip()
            if not line_stripped:
                continue
            # 匹配新主section
            main_match = main_section_pattern.match(line_stripped)
            if main_match:
                if current_main:
                    main_sections.append(current_main)
                main_name = main_match.group(1)
                current_main = {"name": main_name, "lines": [line_stripped]}
            elif current_main:
                current_main["lines"].append(line_stripped)
    if current_main:
        main_sections.append(current_main)

    # 分析子section，计算主section信息
    result_list = []
    for main_sec in main_sections:
        main_name = main_sec["name"]
        sec_lines = main_sec["lines"]
        subsections = []
        current_sub_name = None
        # 提取子section
        for line in sec_lines:
            line_stripped = line.rstrip()
            if not line_stripped:
                continue
            # 处理跨线子section地址行
            if current_sub_name:
                addr_match = sub_addr_pattern.match(line_stripped)
                if addr_match:
                    start = int(addr_match.group(1), 16)
                    size = int(addr_match.group(2), 16)
                    subsections.append({"start": start, "size": size})
                    current_sub_name = None
                continue
            # 处理单行子section
            single_match = single_sub_pattern.match(line_stripped)
            if single_match:
                start = int(single_match.group(3), 16)
                size = int(single_match.group(4), 16)
                subsections.append({"start": start, "size": size})
                continue
            # 处理跨线子section名称行
            sub_name_match = sub_name_pattern.match(line_stripped)
            if sub_name_match:
                current_sub_name = sub_name_match.group(1)
                continue

        # 计算主section地址、大小
        if not subsections:
            main_match = main_section_pattern.match(sec_lines[0])
            if main_match:
                start_int = int(main_match.group(2), 16)
                size_bytes = int(main_match.group(3), 16)
            else:
                print(f"❌ 跳过无效section: {main_name}")
                continue
        else:
            start_int = min(ss["start"] for ss in subsections)
            end_int = max(ss["start"] + ss["size"] for ss in subsections)
            size_bytes = end_int - start_int

        size_kb = round(size_bytes / 1024, 2)
        end_int = start_int + size_bytes
        start_hex = f"0x{start_int:08x}"
        end_hex = f"0x{end_int:08x}"

        if size_kb <= 0:
            print(f"❌ 跳过空section: {main_name}")
            continue

        result_list.append(
            {
                "name": main_name,
                "start_int": start_int,
                "start_hex": start_hex,
                "size_kb": size_kb,
                "size_bytes": size_bytes,
                "end_int": end_int,
                "end_hex": end_hex,
            }
        )
    return result_list


# --------------------------
# 2. 分类 Flash 和 RAM 数据
# --------------------------
def classify_memory_sections(section_list):
    FLASH_THRESHOLD = 0x10000000  # 简化为 0x10000000
    flash_list, ram_list = [], []
    for sec in section_list:
        if sec["start_int"] >= FLASH_THRESHOLD:
            flash_list.append(sec)
        else:
            ram_list.append(sec)
    # 按起始地址排序（便于重叠检测）
    flash_list.sort(key=lambda x: x["start_int"])
    ram_list.sort(key=lambda x: x["start_int"])
    return flash_list, ram_list


# --------------------------
# 3. 绘制分布图表（边框样式优化：主题色边框/无边框）
# --------------------------
def plot_memory_distribution(flash_list, ram_list):
    # 解决中文乱码
    plt.rcParams["font.sans-serif"] = ["SimHei", "WenQuanYi Micro Hei"]
    plt.rcParams["axes.unicode_minus"] = False

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10), constrained_layout=True)
    fig.suptitle(
        "主Section存储分布图表（边框：主题色/无边框）", fontsize=16, fontweight="bold"
    )

    # --------------------------
    # 核心1：检测所有重叠的Section（无遗漏）
    def detect_all_overlaps(section_list, normal_color, overlap_color):
        overlap_set = set()
        n = len(section_list)
        for i in range(n):
            sec_i = section_list[i]
            for j in range(i + 1, n):
                sec_j = section_list[j]
                if sec_j["start_int"] < sec_i["end_int"]:
                    overlap_set.add(sec_i["name"])
                    overlap_set.add(sec_j["name"])
        colors = []
        for sec in section_list:
            colors.append(overlap_color if sec["name"] in overlap_set else normal_color)
        return colors, overlap_set, len(overlap_set) > 0

    # --------------------------
    # 核心2：生成方块边框参数（非重叠：主题色边框；重叠：无边框）
    def get_bar_border_params(is_overlap, normal_color):
        if is_overlap:
            # 重叠方块：无边框（linewidth=0）
            return {"edgecolor": "none", "linewidth": 0}
        else:
            # 非重叠方块：边框颜色=主题色，线宽1（与主题融合）
            return {"edgecolor": normal_color, "linewidth": 1}

    # --------------------------
    # 辅助函数：生成对齐16进制的X轴刻度
    def generate_hex_ticks(min_addr, max_addr, step=0x10000):
        ticks = []
        current = (min_addr // step) * step
        while current <= max_addr:
            ticks.append(current)
            current += step
        if ticks and ticks[-1] < max_addr:
            ticks.append(max_addr)
        return ticks

    # --------------------------
    # Flash 分布（0x10000000 以上）
    # --------------------------
    flash_overlap_set = set()
    flash_has_overlap = False
    if flash_list:
        flash_normal = "#4ECDC4"  # Flash主题色（青色）
        flash_overlap = "#FF6B6B"  # 重叠色（红色）
        flash_colors, flash_overlap_set, flash_has_overlap = detect_all_overlaps(
            flash_list, flash_normal, flash_overlap
        )

        # 绘图数据
        flash_names = [sec["name"] for sec in flash_list]
        flash_starts = [sec["start_int"] for sec in flash_list]
        flash_sizes = [sec["size_bytes"] for sec in flash_list]
        flash_start_hex = [sec["start_hex"] for sec in flash_list]
        flash_end_hex = [sec["end_hex"] for sec in flash_list]
        flash_size_kb = [sec["size_kb"] for sec in flash_list]

        # 绘制水平条形图（按重叠状态设置边框）
        for i in range(len(flash_names)):
            is_overlap = flash_names[i] in flash_overlap_set
            border_params = get_bar_border_params(is_overlap, flash_normal)
            ax1.barh(
                i,
                flash_sizes[i],
                left=flash_starts[i],
                color=flash_colors[i],
                alpha=0.7,
                **border_params,  # 应用边框参数
            )

        # Y轴隐藏重复名称
        ax1.set_yticks(range(len(flash_names)))
        ax1.set_yticklabels([""] * len(flash_names), fontsize=10)

        # 左侧标注「名称（红）+ 起始地址」
        for i, (start, name, hex_addr) in enumerate(
            zip(flash_starts, flash_names, flash_start_hex)
        ):
            text_color = "red" if name in flash_overlap_set else "black"
            ax1.text(
                start - 256,
                i,
                f"{name}\n{hex_addr}",
                va="center",
                ha="right",
                fontsize=9,
                color=text_color,
                bbox=dict(facecolor="none", edgecolor="none", alpha=0),
            )

        # 右侧标注「结束地址 + 大小」
        for i, (end, hex_end, size) in enumerate(
            zip([sec["end_int"] for sec in flash_list], flash_end_hex, flash_size_kb)
        ):
            text_color = "red" if flash_names[i] in flash_overlap_set else "black"
            ax1.text(
                end + 256,
                i,
                f"{hex_end}\n{size:.2f}KB",
                va="center",
                fontsize=9,
                color=text_color,
                bbox=dict(facecolor="none", edgecolor="none", alpha=0),
            )

        # X轴刻度
        min_addr = min(sec["start_int"] for sec in flash_list)
        max_addr = max(sec["end_int"] for sec in flash_list)
        flash_ticks = generate_hex_ticks(min_addr, max_addr, step=0x10000)
        ax1.set_xticks(flash_ticks)
        ax1.set_xticklabels([f"0x{tick:08x}" for tick in flash_ticks], rotation=45)

        ax1.set_xlabel("地址", fontsize=12)
        ax1.set_title("Flash 主Section分布（地址 ≥ 0x10000000）", fontsize=14)
        ax1.grid(axis="x", alpha=0.3, linestyle="--")
        ax1.set_xlim(min_addr - 0x10000, max_addr + 0x10000)

    else:
        ax1.text(
            0.5,
            0.5,
            "未识别到Flash主Section",
            ha="center",
            va="center",
            transform=ax1.transAxes,
        )
        ax1.set_title("Flash 主Section分布（地址 ≥ 0x10000000）", fontsize=14)
        ax1.set_xlabel("地址", fontsize=12)

    # --------------------------
    # RAM 分布（0 ~ 0x7FFFFFFF）
    # --------------------------
    ram_overlap_set = set()
    ram_has_overlap = False
    if ram_list:
        ram_normal = "#FFD166"  # RAM主题色（黄色）
        ram_overlap = "#FF6B6B"  # 重叠色（红色）
        ram_colors, ram_overlap_set, ram_has_overlap = detect_all_overlaps(
            ram_list, ram_normal, ram_overlap
        )

        # 绘图数据
        ram_names = [sec["name"] for sec in ram_list]
        ram_starts = [sec["start_int"] for sec in ram_list]
        ram_sizes = [sec["size_bytes"] for sec in ram_list]
        ram_start_hex = [sec["start_hex"] for sec in ram_list]
        ram_end_hex = [sec["end_hex"] for sec in ram_list]
        ram_size_kb = [sec["size_kb"] for sec in ram_list]

        # 绘制水平条形图（按重叠状态设置边框）
        for i in range(len(ram_names)):
            is_overlap = ram_names[i] in ram_overlap_set
            border_params = get_bar_border_params(is_overlap, ram_normal)
            ax2.barh(
                i,
                ram_sizes[i],
                left=ram_starts[i],
                color=ram_colors[i],
                alpha=0.7,
                **border_params,  # 应用边框参数
            )

        # Y轴隐藏重复名称
        ax2.set_yticks(range(len(ram_names)))
        ax2.set_yticklabels([""] * len(ram_names), fontsize=10)

        # 左侧标注「名称（红）+ 起始地址」
        for i, (start, name, hex_addr) in enumerate(
            zip(ram_starts, ram_names, ram_start_hex)
        ):
            text_color = "red" if name in ram_overlap_set else "black"
            ax2.text(
                start - 256,
                i,
                f"{name}\n{hex_addr}",
                va="center",
                ha="right",
                fontsize=9,
                color=text_color,
                bbox=dict(facecolor="none", edgecolor="none", alpha=0),
            )

        # 右侧标注「结束地址 + 大小」
        for i, (end, hex_end, size) in enumerate(
            zip([sec["end_int"] for sec in ram_list], ram_end_hex, ram_size_kb)
        ):
            text_color = "red" if ram_names[i] in ram_overlap_set else "black"
            ax2.text(
                end + 256,
                i,
                f"{hex_end}\n{size:.2f}KB",
                va="center",
                fontsize=9,
                color=text_color,
                bbox=dict(facecolor="none", edgecolor="none", alpha=0),
            )

        # X轴刻度（包含0）
        min_addr = min(sec["start_int"] for sec in ram_list) if ram_list else 0
        max_addr = max(sec["end_int"] for sec in ram_list) if ram_list else 0
        ram_ticks = generate_hex_ticks(min_addr, max_addr, step=0x10000)
        if 0 not in ram_ticks:
            ram_ticks.insert(0, 0)
        ax2.set_xticks(ram_ticks)
        ax2.set_xticklabels([f"0x{tick:08x}" for tick in ram_ticks], rotation=45)

        ax2.set_xlabel("地址", fontsize=12)
        ax2.set_title("RAM 主Section分布（地址 < 0x10000000）", fontsize=14)
        ax2.grid(axis="x", alpha=0.3, linestyle="--")
        ax2.set_xlim(min(0, min_addr - 0x10000), max_addr + 0x10000)

    else:
        ax2.text(
            0.5,
            0.5,
            "未识别到RAM主Section",
            ha="center",
            va="center",
            transform=ax2.transAxes,
        )
        ax2.set_title("RAM 主Section分布（地址 < 0x10000000）", fontsize=14)
        ax2.set_xlabel("地址", fontsize=12)

    # 命令行打印所有重叠的Section
    if flash_has_overlap:
        print("\n⚠️ Flash中地址重叠的主Section：")
        for name in sorted(flash_overlap_set):
            print(f"- {name}")
    if ram_has_overlap:
        print("\n⚠️ RAM中地址重叠的主Section：")
        for name in sorted(ram_overlap_set):
            print(f"- {name}")
    if not (flash_has_overlap or ram_has_overlap):
        print("\n✅ 所有主Section地址无重叠")

    # 保存并显示图表
    plt.savefig(
        "memory_distribution_border_optimized.png", dpi=300, bbox_inches="tight"
    )
    plt.show()


# --------------------------
# 主执行流程
# --------------------------
if __name__ == "__main__":
    map_file_path = "map.txt"  # 修改为实际map.txt路径
    try:
        section_list = parse_map_file(map_file_path)
        print(f"✅ 解析到 {len(section_list)} 个有效主Section")
    except FileNotFoundError:
        print(f"❌ 未找到文件 {map_file_path}，请检查路径")
        exit()
    except Exception as e:
        print(f"❌ 解析错误：{str(e)}")
        exit()

    flash_list, ram_list = classify_memory_sections(section_list)
    print(f"📊 Flash Section数：{len(flash_list)} | RAM Section数：{len(ram_list)}")

    try:
        plot_memory_distribution(flash_list, ram_list)
    except ImportError:
        print("❌ 缺少matplotlib库，请执行：pip install matplotlib")
    except Exception as e:
        print(f"❌ 绘图错误：{str(e)}")
