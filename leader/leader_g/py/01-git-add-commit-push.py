# 接收一个命令行参数作为git commit -F的提交信息文件
# 区分处理已修改文件和未跟踪文件，先提交已修改文件
# 对文件大小进行检查：
# 单个文件超过 500MB 会被跳过并显示警告
# 总大小超过 500MB 时会分多次提交
# 每次提交按文件大小从小到大排序
# 包含错误处理和重试机制：
# git push操作失败时会重试，最多 5 次
# 任何步骤失败都会显示错误信息并退出程序
# 使用方法：
# python git_batch_commit.py commit_message.txt
# 其中commit_message.txt是包含你的提交信息的文件。
# 脚本会自动处理所有未提交文件，按照设定的规则分批次提交和推送。


import os
import sys
import time
import tempfile

# 常量定义
MAX_BATCH_SIZE = 500 * 1024 * 1024  # 500MB
MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024  # 单个文件最大500MB
MAX_RETRIES = 5  # 最大重试次数


def run_command(command):
    """执行命令并返回(成功标志, 输出内容)"""
    # 创建临时文件存储输出
    with tempfile.NamedTemporaryFile(mode="w+", delete=False, encoding="utf-8") as f:
        temp_file = f.name

    # 执行命令并将输出重定向到临时文件
    exit_code = os.system(f'{command} > "{temp_file}" 2>&1')
    success = exit_code == 0

    # 读取输出内容
    output = ""
    try:
        with open(temp_file, "r", encoding="utf-8") as f:
            output = f.read()
    except UnicodeDecodeError:
        # 尝试用GBK编码读取，适应Windows系统
        with open(temp_file, "r", encoding="gbk") as f:
            output = f.read()
    finally:
        os.remove(temp_file)

    return success, output


def get_file_size(file_path):
    """获取文件大小(字节)"""
    try:
        return os.path.getsize(file_path)
    except OSError as e:
        print(f"警告: 无法获取文件 '{file_path}' 的大小 - {str(e)}")
        return 0


def get_uncommitted_files():
    """获取已修改和未跟踪的文件列表"""
    # 获取已修改文件
    success, modified_output = run_command("git diff --name-only")
    modified_files = (
        [f.strip() for f in modified_output.splitlines() if f.strip()]
        if success
        else []
    )

    # 获取未跟踪文件
    success, untracked_output = run_command("git ls-files --others --exclude-standard")
    untracked_files = (
        [f.strip() for f in untracked_output.splitlines() if f.strip()]
        if success
        else []
    )

    return modified_files, untracked_files


def commit_and_push(files, commit_msg_file):
    """提交文件并推送，包含重试机制"""
    if not files:
        print("没有文件需要提交")
        return True

    # 添加文件
    files_quoted = [f'"{f}"' for f in files]
    add_cmd = f'git add {" ".join(files_quoted)}'
    success, output = run_command(add_cmd)
    if not success:
        print(f"添加文件失败: {output}")
        return False

    # 提交文件
    commit_cmd = f'git commit -F "{commit_msg_file}"'
    success, output = run_command(commit_cmd)
    if not success:
        print(f"提交失败: {output}")
        return False

    print(f"成功提交 {len(files)} 个文件")

    # 推送，带重试机制
    for i in range(MAX_RETRIES):
        print(f"正在推送 (尝试 {i+1}/{MAX_RETRIES})...")
        success, output = run_command("git push")
        if success:
            print("推送成功")
            return True
        print(f"推送失败: {output}")
        if i < MAX_RETRIES - 1:
            print("等待2秒后重试...")
            time.sleep(2)

    print(f"达到最大重试次数 ({MAX_RETRIES})，推送失败")
    return False


def main():
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("需要一个参数，例如: commit_info.txt")
        sys.exit(1)

    # 处理提交信息文件
    original_commit_file = sys.argv[1]
    if not os.path.exists(original_commit_file):
        print(f"错误: 提交信息文件 '{original_commit_file}' 不存在")
        sys.exit(1)

    # 处理提交信息，过滤注释和空行
    try:
        with open(original_commit_file, "rb") as f:
            lines = f.readlines()

        push_allow = False
        commit_msg_file = original_commit_file + ".tmp"

        with open(commit_msg_file, "wb") as f:
            for line in lines:
                if line[:2] == b"# ":
                    continue
                if not line.strip():
                    continue
                f.write(line.strip() + b"\n")
                push_allow = True

        if not push_allow:
            print(f"错误: 提交信息文件内容为空: {original_commit_file}")
            os.remove(commit_msg_file)
            sys.exit(2)

    except Exception as e:
        print(f"处理提交信息文件时出错: {str(e)}")
        sys.exit(1)

    # 获取未提交文件
    modified_files, untracked_files = get_uncommitted_files()
    print(
        f"发现 {len(modified_files)} 个已修改文件，{len(untracked_files)} 个未跟踪文件"
    )

    # 先提交已修改的文件
    if modified_files:
        print(f"正在提交 {len(modified_files)} 个已修改文件...")
        if not commit_and_push(modified_files, commit_msg_file):
            print("提交已修改文件失败，程序退出")
            os.remove(commit_msg_file)
            sys.exit(1)

    # 处理未跟踪文件
    if not untracked_files:
        print("没有未跟踪文件需要提交")
        os.remove(commit_msg_file)
        sys.exit(0)

    # 检查文件大小并过滤过大文件
    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(
                f"警告: 文件 '{file}' 大小为 {file_size/1024/1024:.2f}MB，超过500MB，已跳过"
            )
            continue
        filtered_files.append((file, file_size))

    # 按文件大小从小到大排序
    filtered_files.sort(key=lambda x: x[1])
    print(f"过滤后剩余 {len(filtered_files)} 个未跟踪文件需要提交")

    # 分批次提交
    current_batch = []
    current_size = 0

    for file, size in filtered_files:
        # 如果添加当前文件会超过批次大小，则提交当前批次
        if current_size + size > MAX_BATCH_SIZE:
            if current_batch:
                print(
                    f"提交当前批次 ({len(current_batch)} 个文件，总大小 {current_size/1024/1024:.2f}MB)..."
                )
                if not commit_and_push(current_batch, commit_msg_file):
                    print("提交失败，程序退出")
                    os.remove(commit_msg_file)
                    sys.exit(1)

                # 重置批次
                current_batch = []
                current_size = 0

        current_batch.append(file)
        current_size += size

    # 提交最后一批文件
    if current_batch:
        print(
            f"提交最后一批 ({len(current_batch)} 个文件，总大小 {current_size/1024/1024:.2f}MB)..."
        )
        if not commit_and_push(current_batch, commit_msg_file):
            print("提交失败，程序退出")
            os.remove(commit_msg_file)
            sys.exit(1)

    # 清理临时文件
    os.remove(commit_msg_file)
    print("所有文件提交完成")


if __name__ == "__main__":
    # 设置代码页为UTF-8以支持中文显示
    os.system("chcp 65001 > nul")
    main()
