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
import argparse
import time
import tempfile

GLOBAL_ENCODING = "utf-8"
WINDOWS_TERMINAL_ENCODING = "gbk"


def safe_print(text):
    """Safely print text, auto-adapt to terminal encoding"""
    try:
        print(
            text.encode(WINDOWS_TERMINAL_ENCODING, errors="replace").decode(
                WINDOWS_TERMINAL_ENCODING
            )
        )
    except:
        print(text.encode(GLOBAL_ENCODING, errors="replace").decode(GLOBAL_ENCODING))


def run_command(command):
    """Execute command with os.system, return (success, output)"""
    # 创建临时文件存储输出
    with tempfile.NamedTemporaryFile(
        mode="w+", delete=False, encoding=GLOBAL_ENCODING
    ) as f:
        temp_file = f.name

    # 重定向 stdout 和 stderr 到临时文件
    cmd = f'{command} > "{temp_file}" 2>&1'

    # 设置Git编码环境变量
    env_vars = (
        (f"set GIT_COMMITTER_ENCODING=utf-8 && " f"set GIT_AUTHOR_ENCODING=utf-8 && ")
        if os.name == "nt"
        else (f"GIT_COMMITTER_ENCODING=utf-8 " f"GIT_AUTHOR_ENCODING=utf-8 ")
    )

    os.system("chcp")
    exit_code = os.system(f"chcp 65001&{env_vars}{cmd}")
    success = exit_code == 0

    # 读取输出内容
    output = ""
    try:
        with open(temp_file, "r", encoding=GLOBAL_ENCODING) as f:
            output = f.read()
    except UnicodeDecodeError:
        # 尝试用系统编码读取
        with open(temp_file, "r", encoding=WINDOWS_TERMINAL_ENCODING) as f:
            output = f.read()
    finally:
        os.remove(temp_file)  # 清理临时文件

    return success, output


def get_uncommitted_files():
    """Get uncommitted files using os.system"""
    success, modified = run_command("git diff --name-only")
    modified = modified if success else ""
    success, untracked = run_command("git ls-files --others --exclude-standard")
    untracked = untracked if success else ""

    modified_files = [f.strip() for f in modified.splitlines() if f.strip()]
    untracked_files = [f.strip() for f in untracked.splitlines() if f.strip()]
    return modified_files, untracked_files


def get_file_size(file_path):
    """Get file size (in bytes)"""
    try:
        file_path = file_path.encode(GLOBAL_ENCODING).decode(GLOBAL_ENCODING)
        return os.path.getsize(file_path)
    except OSError as e:
        safe_print(f"Warning: Failed to get size of file {file_path}, error: {str(e)}")
        return 0


def commit_files(files, commit_msg_file):
    """Commit specified files"""
    if not files:
        safe_print("No files need to be committed")
        return True

    # 添加文件
    files_quoted = [f'"{f}"' for f in files]
    add_cmd = f'git add {" ".join(files_quoted)}'
    success, output = run_command(add_cmd)
    if not success:
        safe_print(f"Failed to add files: {output}")
        return False

    # 提交文件（指定编码）
    commit_cmd = f'git -c i18n.commitencoding=utf-8 commit -F "{commit_msg_file}"'
    success, output = run_command(commit_cmd)
    if not success:
        safe_print(f"Commit failed: {output}")
        return False

    safe_print(f"Successfully committed {len(files)} files:\n{output}")
    return True


def push_with_retry(max_retries=5):
    """Push commits with retry mechanism"""
    for i in range(max_retries):
        safe_print(f"Pushing (attempt {i+1}/{max_retries})...")
        success, output = run_command("git push")
        if success:
            safe_print(f"Push succeeded:\n{output}")
            return True
        safe_print(f"Push failed (attempt {i+1}):\n{output}")
        if i < max_retries - 1:
            safe_print("Waiting 2 seconds before retrying...")
            time.sleep(2)

    safe_print(f"Reached maximum retries ({max_retries}), push failed")
    return False


def main():
    parser = argparse.ArgumentParser(
        description="Batch commit Git files (os.system version)"
    )
    parser.add_argument("commit_msg_file", help="Path to commit message file (UTF-8)")
    args = parser.parse_args()
    commit_msg_file = args.commit_msg_file

    if not os.path.exists(commit_msg_file):
        safe_print(f"Error: Commit message file {commit_msg_file} does not exist")
        sys.exit(1)

    temp_commit_file = f"{commit_msg_file}.tmp"
    push_allow = False
    try:
        with open(commit_msg_file, "rt", encoding=GLOBAL_ENCODING) as f:
            lines = f.readlines()

        with open(temp_commit_file, "wt", encoding=GLOBAL_ENCODING) as f:
            for line in lines:
                line_stripped = line.strip()
                if line_stripped.startswith("#") or not line_stripped:
                    continue
                f.write(f"{line_stripped}\n")
                push_allow = True

        if not push_allow:
            safe_print(f"Error: Commit message file {commit_msg_file} is empty")
            os.remove(temp_commit_file)
            sys.exit(2)

    except UnicodeDecodeError:
        safe_print(f"Error: Commit message file {commit_msg_file} is not UTF-8 encoded")
        sys.exit(1)
    except Exception as e:
        safe_print(f"Failed to process commit message file: {str(e)}")
        if os.path.exists(temp_commit_file):
            os.remove(temp_commit_file)
        sys.exit(1)

    MAX_BATCH_SIZE = 500 * 1024 * 1024
    MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024

    modified_files, untracked_files = get_uncommitted_files()
    safe_print(
        f"Found {len(modified_files)} modified files, {len(untracked_files)} untracked files"
    )

    if modified_files:
        safe_print(f"Committing {len(modified_files)} modified files...")
        if commit_files(modified_files, temp_commit_file):
            if not push_with_retry():
                safe_print("Push failed after committing modified files, exiting")
                os.remove(temp_commit_file)
                sys.exit(1)
        else:
            safe_print("Failed to commit modified files, exiting")
            os.remove(temp_commit_file)
            sys.exit(1)

    if not untracked_files:
        safe_print("No untracked files need to be committed")
        os.remove(temp_commit_file)
        sys.exit(0)

    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"Warning: File {file} is {file_size/1024/1024:.2f}MB, exceeding 500MB, skipped"
            )
            continue
        filtered_files.append((file, file_size))

    filtered_files.sort(key=lambda x: x[1])
    safe_print(f"{len(filtered_files)} untracked files remaining after filtering")

    current_batch = []
    current_size = 0
    for file, size in filtered_files:
        if current_size + size > MAX_BATCH_SIZE:
            if current_batch:
                safe_print(
                    f"Committing current batch ({len(current_batch)} files, {current_size/1024/1024:.2f}MB)..."
                )
                if commit_files(current_batch, temp_commit_file):
                    if not push_with_retry():
                        safe_print("Push failed, exiting")
                        os.remove(temp_commit_file)
                        sys.exit(1)
                else:
                    safe_print("Commit failed, exiting")
                    os.remove(temp_commit_file)
                    sys.exit(1)
                current_batch = []
                current_size = 0

        current_batch.append(file)
        current_size += size

    if current_batch:
        safe_print(
            f"Committing last batch ({len(current_batch)} files, {current_size/1024/1024:.2f}MB)..."
        )
        if commit_files(current_batch, temp_commit_file):
            if not push_with_retry():
                safe_print("Push failed, exiting")
                os.remove(temp_commit_file)
                sys.exit(1)
        else:
            safe_print("Commit failed, exiting")
            os.remove(temp_commit_file)
            sys.exit(1)

    os.remove(temp_commit_file)
    safe_print("All files committed successfully")


if __name__ == "__main__":
    main()
