import xml.etree.ElementTree as ET
import sys
import os
from typing import List, Dict


def parse_cbp(cbp_path: str) -> Dict:
    """解析CBp，所有路径强制用正斜杠（禁用os.path.join避免Windows反斜杠）"""
    if not os.path.exists(cbp_path):
        raise FileNotFoundError(f"CBp文件不存在：{cbp_path}")

    tree = ET.parse(cbp_path)
    root = tree.getroot()
    project_node = root.find("Project")
    if project_node is None:
        raise ValueError("CBp缺少<Project>节点")

    # 1. 项目名（确保不为空）
    project_title = (
        project_node.findtext("./Option[@title]", default="app").strip() or "app"
    )

    # 2. 编译器配置（编译选项+包含目录，彻底去反斜杠）
    compiler_node = project_node.find("Compiler")
    compile_options: List[str] = []
    include_dirs: List[str] = []
    if compiler_node is not None:
        # 编译选项
        for add_opt in compiler_node.findall("./Add[@option]"):
            opt = add_opt.get("option", "").strip().replace("\\", "/")  # 强制正斜杠
            if opt:
                compile_options.append(opt)

        # 包含目录：禁用os.path.join，手动拼接正斜杠
        for add_dir in compiler_node.findall("./Add[@directory]"):
            cbp_dir = add_dir.get("directory", "").strip().replace("\\", "/")
            if not cbp_dir:
                continue

            # 路径转换：../../platform → app/platform；./display → app/projects/standard/display
            if cbp_dir.startswith("../../"):
                converted_dir = cbp_dir.replace("../../", "app/", 1)
            elif cbp_dir.startswith("."):
                # 手动拼接，避免os.path.join生成反斜杠
                converted_dir = f"app/projects/standard/{cbp_dir.lstrip('./')}"
            else:
                converted_dir = f"app/projects/standard/{cbp_dir}"

            # 双重保险：再转一次正斜杠+去除末尾斜杠
            converted_dir = converted_dir.replace("\\", "/").rstrip("/")
            include_dirs.append(f"${{PROJECT_SOURCE_DIR}}/{converted_dir}")

    # 3. 源文件（.c + ram.ld，禁用os.path.join，全用正斜杠）
    src_files: List[str] = []
    special_files: List[str] = []
    for unit_node in project_node.findall("Unit"):
        unit_filename = (
            unit_node.get("filename", "").strip().replace("\\", "/")
        )  # 先转正斜杠
        if not unit_filename or unit_filename.endswith((".h", ".xm")):
            continue

        # 路径转换：禁用os.path.join，手动拼接（关键修复）
        if unit_filename.startswith("../../"):
            converted_path = unit_filename.replace("../../", "app/", 1)
        else:
            # 手动拼接路径，确保用正斜杠（比如 "standard/config.c" → "app/projects/standard/config.c"）
            converted_path = f"app/projects/standard/{unit_filename}"

        # 双重保险：再次替换反斜杠+去除末尾斜杠（防止任何残留）
        converted_path = converted_path.replace("\\", "/").rstrip("/")
        full_path = f"${{PROJECT_SOURCE_DIR}}/{converted_path}"

        # 标记特殊文件（ram.ld）
        if os.path.basename(converted_path) == "ram.ld":
            special_files.append(full_path)
        elif converted_path.endswith(".c"):
            src_files.append(full_path)

    # 4. 链接器配置（修复链接脚本路径+去反斜杠）
    linker_node = project_node.find("Linker")
    link_options: List[str] = []
    link_libraries: List[str] = []
    link_dirs: List[str] = []
    if linker_node is not None:
        # 链接选项：修复链接脚本路径+去反斜杠
        for add_opt in linker_node.findall("./Add[@option]"):
            opt = add_opt.get("option", "").strip().replace("\\", "/")
            if not opt:
                continue
            # 修复链接脚本路径：-T$(TARGET_OBJECT_DIR)ram.o → -T${CMAKE_CURRENT_BINARY_DIR}/ram.o
            opt = opt.replace(
                "-T$(TARGET_OBJECT_DIR)ram.o", "-T${CMAKE_CURRENT_BINARY_DIR}/ram.o"
            )
            opt = opt.replace(
                "Output/bin/map.txt", "${PROJECT_SOURCE_DIR}/Output/bin/map.txt"
            )
            link_options.append(opt)

        # 链接库（补全.a后缀）
        for add_lib in linker_node.findall("./Add[@library]"):
            lib_name = add_lib.get("library", "").strip()
            if lib_name:
                link_libraries.append(
                    f"{lib_name}.a" if not lib_name.endswith(".a") else lib_name
                )

        # 库目录：去反斜杠
        for add_dir in linker_node.findall("./Add[@directory]"):
            cbp_lib_dir = add_dir.get("directory", "").strip().replace("\\", "/")
            if not cbp_lib_dir:
                continue
            converted_lib_dir = cbp_lib_dir.replace("../../", "app/", 1).rstrip("/")
            link_dirs.append(f"${{PROJECT_SOURCE_DIR}}/{converted_lib_dir}")

    # 5. 预/后构建命令（去反斜杠）
    extra_cmds_node = project_node.find("ExtraCommands")
    pre_build: List[str] = []
    post_build: List[str] = []
    if extra_cmds_node is not None:
        for cmd_node in extra_cmds_node.findall("./Add[@before]"):
            cmd = (
                cmd_node.text.strip().replace("\\", "/") if cmd_node.text else ""
            ).replace("$(PROJECT_NAME)", "${PROJECT_NAME}")
            if cmd:
                pre_build.append(cmd)
        for cmd_node in extra_cmds_node.findall("./Add[@after]"):
            cmd = (
                cmd_node.text.strip().replace("\\", "/") if cmd_node.text else ""
            ).replace("$(PROJECT_NAME)", "${PROJECT_NAME}")
            if cmd:
                post_build.append(cmd)

    return {
        "title": project_title,
        "compile_opts": compile_options,
        "include_dirs": include_dirs,
        "src_files": src_files,
        "special_files": special_files,
        "link_opts": link_options,
        "link_libs": link_libraries,
        "link_dirs": link_dirs,
        "pre_build": pre_build,
        "post_build": post_build,
    }


def generate_cmake(config: Dict, output_path: str) -> None:
    """生成CMakeLists.txt，所有路径强制正斜杠"""
    # 处理ram.ld编译命令（去反斜杠）
    ram_cmd = ""
    special_objs = []
    if config["special_files"]:
        ram_ld = config["special_files"][0].replace("\\", "/")  # 再次确认正斜杠
        ram_o = "${CMAKE_CURRENT_BINARY_DIR}/ram.o"
        special_objs.append(ram_o)
        ram_cmd = f"""# 编译链接脚本ram.ld
add_custom_command(
    OUTPUT {ram_o}
    COMMAND ${{CMAKE_C_COMPILER}} ${{CMAKE_C_FLAGS}} ${{CMAKE_C_INCLUDE_DIRECTORIES}} 
            -E -P -x c -c {ram_ld} 
            -o {ram_o}
    DEPENDS {ram_ld}
    COMMENT "Compiling link script: {ram_ld} → {ram_o}"
)

"""

    # 源文件列表（确保无反斜杠）
    src_list = (
        "\n    ".join([src.replace("\\", "/") for src in config["src_files"]])
        if config["src_files"]
        else ""
    )
    special_list = "\n    ".join(special_objs) if special_objs else ""
    all_src = (
        f"{special_list}\n    {src_list}".strip()
        if special_list and src_list
        else (special_list or src_list)
    )

    # 其他配置列表（去反斜杠）
    include_list = (
        "\n    ".join([inc.replace("\\", "/") for inc in config["include_dirs"]])
        if config["include_dirs"]
        else ""
    )
    compile_opt_list = (
        "\n    ".join(config["compile_opts"]) if config["compile_opts"] else ""
    )
    link_dir_list = (
        "\n    ".join([dir.replace("\\", "/") for dir in config["link_dirs"]])
        if config["link_dirs"]
        else ""
    )
    link_opt_list = "\n    ".join(config["link_opts"]) if config["link_opts"] else ""
    link_lib_list = "\n    ".join(config["link_libs"]) if config["link_libs"] else ""

    # 生成CMake内容（自动包含compile_commands导出）
    cmake_content = f"""cmake_minimum_required(VERSION 3.5)

# 1. 项目配置
set(PROJECT_NAME "{config['title']}")
project(${{PROJECT_NAME}})

# 自动生成compile_commands.json（供clangd使用）
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 2. RISC-V交叉编译配置
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER riscv32-unknown-elf-gcc)
set(CMAKE_C_STANDARD 99)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-nostdlib")

# 3. 输出目录
file(MAKE_DIRECTORY ${{PROJECT_SOURCE_DIR}}/Output/bin)
file(MAKE_DIRECTORY ${{PROJECT_SOURCE_DIR}}/Output/obj)

# 4. 链接脚本处理
{ram_cmd}

# 5. 可执行文件（路径全为正斜杠）
add_executable(${{PROJECT_NAME}}
    {all_src}
)

# 6. 包含目录
if(NOT "${include_list}" STREQUAL "")
target_include_directories(${{PROJECT_NAME}} PUBLIC
    {include_list}
)
endif()

# 7. 编译选项
if(NOT "${compile_opt_list}" STREQUAL "")
target_compile_options(${{PROJECT_NAME}} PRIVATE
    {compile_opt_list}
)
endif()

# 8. 链接配置
if(NOT "${link_dir_list}" STREQUAL "")
link_directories(
    {link_dir_list}
)
endif()

if(NOT "${link_opt_list}" STREQUAL "")
target_link_options(${{PROJECT_NAME}} PRIVATE
    {link_opt_list}
)
endif()

if(NOT "${link_lib_list}" STREQUAL "")
target_link_libraries(${{PROJECT_NAME}} PRIVATE
    {link_lib_list}
)
endif()

# 9. 目标属性
set_target_properties(${{PROJECT_NAME}} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${{PROJECT_SOURCE_DIR}}/Output/bin"
    OUTPUT_NAME "${{PROJECT_NAME}}.rv32"
    OBJECT_OUTPUT_DIRECTORY "${{PROJECT_SOURCE_DIR}}/Output/obj"
    SUFFIX ""
)

"""

    # 预/后构建命令
    if config["pre_build"]:
        cmake_content += "# 10. 预构建命令\n"
        for cmd in config["pre_build"]:
            cmake_content += f'add_custom_command(TARGET ${{PROJECT_NAME}} PRE_BUILD\n    COMMAND {cmd}\n    COMMENT "Pre-build: {cmd}")\n\n'
    if config["post_build"]:
        cmake_content += "# 11. 后构建命令\n"
        for cmd in config["post_build"]:
            cmake_content += f'add_custom_command(TARGET ${{PROJECT_NAME}} POST_BUILD\n    COMMAND {cmd}\n    COMMENT "Post-build: {cmd}")\n'

    # 写入文件
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(cmake_content)
    print(f"✅ 生成成功！路径无反斜杠，已添加compile_commands导出")
    print(f"   CMakeLists.txt路径：{os.path.abspath(output_path)}")


def main():
    if len(sys.argv) != 3:
        print("❌ 用法：python cbp2cmake_no_backslash.py <app.cbp路径> <输出CMake路径>")
        print(
            "   示例：python cbp2cmake_no_backslash.py ./app/projects/standard/app.cbp ./CMakeLists.txt"
        )
        sys.exit(1)

    try:
        cbp_config = parse_cbp(sys.argv[1])
        generate_cmake(cbp_config, sys.argv[2])
    except Exception as e:
        print(f"❌ 失败：{str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
