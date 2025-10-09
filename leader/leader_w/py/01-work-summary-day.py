import datetime
import re
import sys
import pyperclip


def extract_task_title(lines, current_index):
    """从当前行向上查找最近的一级标题作为任务标题"""
    # 从当前行向上遍历
    for i in range(current_index, -1, -1):
        line = lines[i].strip()
        if not line:
            continue
        # 匹配一级标题 (# 开头)
        match = re.match(r"^# (.+)", line)
        if match:
            return match.group(1)
    return None


def extract_task_details(lines, start_index):
    """从起始行向下提取任务详情列表和进度百分比"""
    details = []
    percentage = ""
    # 从起始行下一行开始遍历
    for line in lines[start_index + 1 :]:
        stripped_line = line.strip()
        # 遇到空行或二级标题则停止
        if not stripped_line or stripped_line.startswith("## "):
            break
        # 匹配数字开头的列表项
        list_match = re.match(r"^\d+\. (.+)", stripped_line)
        if not list_match:
            continue
        # 检查是否为汇报项 (# 标记)
        if not re.match(r"^\d+\. #", line.strip()):
            continue

        item_content = list_match.group(1)
        # 提取百分比和内容
        content_match = re.match(r"([^，]+)，(.+)", item_content)
        if content_match:
            percentage_part, detail_part = content_match.groups()
            percentage = percentage_part.strip("#").strip("%") + "%"
            details.append(detail_part)
        else:
            details.append(item_content)

    # 按格式返回结果 (百分比在前，详情在后)
    if percentage:
        return [percentage] + details
    return details


def main():
    # 解析命令行参数
    if len(sys.argv) != 4:
        print(
            "用法: python script.py <工作记录文件路径> <日期(YYYY-MM-DD)> <时间段(morning或其他)>"
        )
        sys.exit(1)

    work_md_path = sys.argv[1]
    target_date = sys.argv[2]
    time_period = sys.argv[3]

    # 读取文件内容
    try:
        with open(work_md_path, "rb") as f:
            file_lines = [line.strip().decode("utf-8") for line in f.readlines()]
    except FileNotFoundError:
        print(f"错误: 找不到文件 {work_md_path}")
        sys.exit(1)
    except Exception as e:
        print(f"读取文件时出错: {e}")
        sys.exit(1)

    # 星期列表
    week_days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    # 解析日期获取星期
    try:
        year, month, day = map(int, target_date.split("-"))
        date_obj = datetime.date(year, month, day)
        week_day = week_days[date_obj.weekday()]
    except ValueError:
        print(f"错误: 日期格式不正确，请使用YYYY-MM-DD格式")
        sys.exit(1)

    # 确定标题类型（计划或进度）
    title_type = "计划" if time_period == "morning" else "进度"
    result_text = f"## 刘德培{target_date}-{week_day}-{title_type}\n"
    task_count = 1

    # 遍历文件行查找目标日期的记录
    for line_idx, line in enumerate(file_lines):
        # 匹配包含目标日期的二级标题
        if re.match(rf"^## {target_date}", line.strip()):
            # 提取任务标题
            task_title = extract_task_title(file_lines, line_idx)
            if not task_title:
                continue

            # 格式化任务标题
            formatted_title = task_title.replace(" ", " 》 ")

            # 提取任务详情
            task_details = extract_task_details(file_lines, line_idx)

            # 构建输出文本
            if not task_details:
                status_text = "未跟进"
                if time_period == "morning":
                    result_text += f"{task_count}. {formatted_title}\n"
                else:
                    result_text += f"{task_count}. {formatted_title} -> {status_text}\n"
            else:
                # 合并详情列表
                details_text = "；".join(
                    [d.strip("。").strip("；") for d in task_details]
                )
                if time_period == "morning":
                    result_text += f"{task_count}. {formatted_title}\n"
                else:
                    result_text += (
                        f"{task_count}. {formatted_title} -> {details_text}\n"
                    )

            task_count += 1

    # 复制结果到剪贴板
    pyperclip.copy(result_text.strip())
    print("提取完成，结果已复制到剪贴板")


if __name__ == "__main__":
    main()
