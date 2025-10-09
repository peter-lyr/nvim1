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

# 常量定义
MAX_BATCH_SIZE = 500 * 1024 * 1024  # 500MB（批次最大总大小）
MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024  # 单个文件最大500MB
MAX_RETRIES = 5  # Git Push最大重试次数


def run_command(command):
    """直接执行命令，输出实时显示在控制台，返回命令是否成功（True/False）"""
    print(f"[执行命令]：{command}")
    # 配置Git编码环境变量（避免中文乱码）
    env_cmd = ""
    if os.name == "nt":  # Windows系统
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
    else:  # 非Windows系统
        env_cmd = "GIT_COMMITTER_ENCODING=utf-8 GIT_AUTHOR_ENCODING=utf-8 "

    # 执行命令（输出直接显示在控制台）
    exit_code = os.system(f"{env_cmd}{command}")
    return exit_code == 0  # 0表示成功，非0表示失败


def get_command_output(command):
    """仅用于需要解析输出的命令（如获取文件列表），返回命令输出内容"""
    import tempfile

    # 创建临时文件存储输出（仅用于解析，不影响控制台显示）
    with tempfile.NamedTemporaryFile(mode="w+", delete=False, encoding="utf-8") as f:
        temp_file = f.name

    # 执行命令并捕获输出
    env_cmd = ""
    if os.name == "nt":
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
    os.system(f'{env_cmd}{command} > "{temp_file}" 2>&1')

    # 读取输出内容
    output = ""
    try:
        with open(temp_file, "r", encoding="utf-8") as f:
            output = f.read()
    except UnicodeDecodeError:
        with open(temp_file, "r", encoding="gbk") as f:
            output = f.read()
    finally:
        os.remove(temp_file)  # 清理临时文件
    return output


def get_file_size(file_path):
    """获取文件大小（字节），返回大小数值"""
    try:
        # 处理路径编码，避免特殊字符导致的路径错误
        file_path = file_path.encode("utf-8", errors="replace").decode("utf-8")
        return os.path.getsize(file_path)
    except OSError as e:
        print(f"[警告]：无法获取文件 '{file_path}' 的大小 - {str(e)}")
        return 0


def get_uncommitted_files():
    """获取已修改文件和未跟踪文件列表，返回(modified_files, untracked_files)"""
    # 获取已修改文件（需解析输出）
    modified_output = get_command_output("git diff --name-only")
    modified_files = [f.strip() for f in modified_output.splitlines() if f.strip()]

    # 获取未跟踪文件（需解析输出）
    untracked_output = get_command_output("git ls-files --others --exclude-standard")
    untracked_files = [f.strip() for f in untracked_output.splitlines() if f.strip()]

    return modified_files, untracked_files


def commit_and_push(files, commit_msg_file):
    """提交指定文件并推送，含Push重试机制，返回是否成功（True/False）"""
    if not files:
        print("[信息]：没有文件需要提交")
        return True

    # 1. Git Add：添加文件（输出直接显示）
    files_quoted = [f'"{f}"' for f in files]  # 处理含空格的文件名
    add_cmd = f"git add {' '.join(files_quoted)}"
    if not run_command(add_cmd):
        print("[失败]：添加文件失败")
        return False

    # 2. Git Commit：提交文件（输出直接显示）
    commit_cmd = f'git commit -F "{commit_msg_file}"'
    if not run_command(commit_cmd):
        print("[失败]：提交文件失败")
        return False

    print(f"[成功]：成功提交 {len(files)} 个文件")

    # 3. Git Push：推送（失败重试，输出直接显示）
    for retry in range(MAX_RETRIES):
        print(f"[推送]：正在推送（尝试 {retry+1}/{MAX_RETRIES}）...")
        push_cmd = "git push"
        if run_command(push_cmd):
            print("[成功]：推送成功")
            return True
        print(f"[失败]：第 {retry+1} 次推送失败")
        if retry < MAX_RETRIES - 1:
            print("[等待]：2秒后重试...")
            time.sleep(2)

    print(f"[失败]：达到最大重试次数（{MAX_RETRIES}次），推送失败")
    return False


def main():
    # 初始化：强制设置控制台编码为UTF-8（Windows）
    if os.name == "nt":
        # 先执行chcp 65001，再验证编码（避免切换不生效）
        os.system("chcp 65001 > nul")
        # 额外设置环境变量，强化UTF-8输出
        os.environ["PYTHONIOENCODING"] = "utf-8"

    # 1. 检查命令行参数
    if len(sys.argv) < 2:
        print("[错误]：缺少参数！用法：python git_batch_commit.py 提交信息文件.txt")
        sys.exit(1)
    original_commit_file = sys.argv[1]

    # 2. 处理提交信息文件（过滤注释和空行）
    if not os.path.exists(original_commit_file):
        print(f"[错误]：提交信息文件 '{original_commit_file}' 不存在")
        sys.exit(1)

    commit_msg_file = f"{original_commit_file}.tmp"  # 临时提交文件
    push_allow = False
    try:
        with open(original_commit_file, "rb") as f:
            lines = f.readlines()
        with open(commit_msg_file, "wb") as f:
            for line in lines:
                if line[:2] == b"# ":  # 跳过注释行（# 开头）
                    continue
                if not line.strip():  # 跳过空行
                    continue
                # 确保写入的内容是UTF-8编码，避免特殊字符
                f.write(line.strip() + b"\n")
                push_allow = True
    except Exception as e:
        print(f"[错误]：处理提交信息文件失败 - {str(e)}")
        # 清理临时文件（若存在）
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)

    if not push_allow:
        print(
            f"[错误]：提交信息文件 '{original_commit_file}' 内容为空（已过滤注释和空行）"
        )
        os.remove(commit_msg_file)
        sys.exit(1)

    # 3. 获取未提交文件列表
    modified_files, untracked_files = get_uncommitted_files()
    print(
        f"[信息]：检测到：{len(modified_files)} 个已修改文件，{len(untracked_files)} 个未跟踪文件"
    )

    # 4. 先提交已修改文件
    if modified_files:
        print(f"\n[提交]：开始提交 {len(modified_files)} 个已修改文件...")
        if not commit_and_push(modified_files, commit_msg_file):
            print("[错误]：已修改文件提交失败，程序退出")
            os.remove(commit_msg_file)
            sys.exit(1)

    # 5. 处理未跟踪文件（无则退出）
    if not untracked_files:
        print("\n[信息]：没有未跟踪文件需要提交，程序结束")
        os.remove(commit_msg_file)
        sys.exit(0)

    # 6. 过滤未跟踪文件（跳过超500MB的文件）
    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(
                f"[警告]：文件 '{file}' 大小 {file_size/1024/1024:.2f}MB（超500MB），已跳过"
            )
            continue
        filtered_files.append((file, file_size))

    # 按文件大小从小到大排序
    filtered_files.sort(key=lambda x: x[1])
    print(f"\n[信息]：过滤后剩余 {len(filtered_files)} 个未跟踪文件（按大小排序）")

    # 7. 分批次提交未跟踪文件
    current_batch = []
    current_batch_size = 0  # 当前批次总大小（字节）

    for file, file_size in filtered_files:
        # 若添加当前文件超批次大小，先提交现有批次
        if current_batch_size + file_size > MAX_BATCH_SIZE:
            print(
                f"\n[提交]：提交当前批次（{len(current_batch)} 个文件，总大小 {current_batch_size/1024/1024:.2f}MB）..."
            )
            if not commit_and_push(current_batch, commit_msg_file):
                print("[错误]：批次提交失败，程序退出")
                os.remove(commit_msg_file)
                sys.exit(1)
            # 重置批次
            current_batch = []
            current_batch_size = 0

        current_batch.append(file)
        current_batch_size += file_size

    # 提交最后一批未提交的文件
    if current_batch:
        print(
            f"\n[提交]：提交最后一批（{len(current_batch)} 个文件，总大小 {current_batch_size/1024/1024:.2f}MB）..."
        )
        if not commit_and_push(current_batch, commit_msg_file):
            print("[错误]：最后一批提交失败，程序退出")
            os.remove(commit_msg_file)
            sys.exit(1)

    # 8. 清理临时文件，结束程序
    os.remove(commit_msg_file)
    print("\n[完成]：所有文件均已成功提交并推送！")


if __name__ == "__main__":
    main()
