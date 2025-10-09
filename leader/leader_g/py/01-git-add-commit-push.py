import os
import sys
import time
import tempfile

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024
MAX_RETRIES = 5


def safe_print(text):
    """安全打印含中文的文本，自动适配控制台编码（解决乱码）"""
    # 获取控制台实际编码（优先stdout编码，无则用UTF-8）
    console_encoding = sys.stdout.encoding if sys.stdout.encoding else "utf-8"
    try:
        # 按控制台编码输出（支持UTF-8/GBK）
        print(text.encode(console_encoding, errors="replace").decode(console_encoding))
    except:
        # 兜底：强制用UTF-8输出
        print(text.encode("utf-8", errors="replace").decode("utf-8"))


def run_command(command):
    """Execute command directly, output to console in real-time. Return success status (True/False)."""
    # 用safe_print替代print，处理中文命令乱码
    safe_print(f"[Executing command]: {command}")
    env_cmd = ""
    if os.name == "nt":
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
    else:
        env_cmd = "GIT_COMMITTER_ENCODING=utf-8 GIT_AUTHOR_ENCODING=utf-8 "
    exit_code = os.system(f"{env_cmd}{command}")
    return exit_code == 0


def get_command_output(command):
    """Only for commands needing output parsing. Return command output."""
    with tempfile.NamedTemporaryFile(mode="w+", delete=False, encoding="utf-8") as f:
        temp_file = f.name
    env_cmd = ""
    if os.name == "nt":
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
    # 执行命令时用safe_print显示含中文的命令
    safe_print(f"[Parsing output]: {command}")
    os.system(f'{env_cmd}{command} > "{temp_file}" 2>&1')
    output = ""
    try:
        with open(temp_file, "r", encoding="utf-8") as f:
            output = f.read()
    except UnicodeDecodeError:
        with open(temp_file, "r", encoding="gbk") as f:
            output = f.read()
    finally:
        os.remove(temp_file)
    return output


def get_file_size(file_path):
    """Get file size (in bytes). Return size value."""
    try:
        # 处理含中文的文件路径编码
        file_path = file_path.encode("utf-8", errors="replace").decode("utf-8")
        return os.path.getsize(file_path)
    except OSError as e:
        # 用safe_print显示含中文的错误信息
        safe_print(f"[Warning]: Failed to get size of file '{file_path}' - {str(e)}")
        return 0


def get_uncommitted_files():
    """Get lists of modified and untracked files. Return (modified_files, untracked_files)."""
    modified_output = get_command_output("git diff --name-only")
    modified_files = [f.strip() for f in modified_output.splitlines() if f.strip()]
    untracked_output = get_command_output("git ls-files --others --exclude-standard")
    untracked_files = [f.strip() for f in untracked_output.splitlines() if f.strip()]
    return modified_files, untracked_files


def commit_and_push(files, commit_msg_file):
    """Commit specified files and push with retry mechanism. Return success status."""
    if not files:
        safe_print("[Info]: No files need to be committed")
        return True
    # 处理含中文的文件路径（用引号包裹）
    files_quoted = [f'"{file}"' for file in files]
    add_cmd = f"git add {' '.join(files_quoted)}"
    if not run_command(add_cmd):
        safe_print("[Error]: Failed to add files")
        return False
    commit_cmd = f'git commit -F "{commit_msg_file}"'
    if not run_command(commit_cmd):
        safe_print("[Error]: Failed to commit files")
        return False
    # 显示含中文的文件数量信息
    safe_print(f"[Success]: Successfully committed {len(files)} files")
    for retry in range(MAX_RETRIES):
        safe_print(f"[Pushing]: Attempt {retry+1}/{MAX_RETRIES}...")
        push_cmd = "git push"
        if run_command(push_cmd):
            safe_print("[Success]: Push completed successfully")
            return True
        safe_print(f"[Error]: Attempt {retry+1} failed")
        if retry < MAX_RETRIES - 1:
            safe_print("[Waiting]: Retrying in 2 seconds...")
            time.sleep(2)
    safe_print(f"[Error]: Maximum retries ({MAX_RETRIES}) reached. Push failed.")
    return False


def main():
    if os.name == "nt":
        # 1. 强制设置控制台为UTF-8编码（解决Windows默认GBK问题）
        os.system("chcp 65001 > nul")
        # 2. 强制Python输出编码为UTF-8
        os.environ["PYTHONIOENCODING"] = "utf-8"
        os.environ["LC_ALL"] = "en_US.UTF-8"  # 额外适配部分终端

    # Check command line arguments
    if len(sys.argv) < 2:
        safe_print(
            "[Error]: Missing argument! Usage: python git_batch_commit.py commit_message_file.txt"
        )
        sys.exit(1)
    original_commit_file = sys.argv[1]
    if not os.path.exists(original_commit_file):
        safe_print(
            f"[Error]: Commit message file '{original_commit_file}' does not exist"
        )
        sys.exit(1)

    # Process commit message file
    commit_msg_file = f"{original_commit_file}.tmp"
    push_allow = False
    try:
        with open(original_commit_file, "rb") as f:
            lines = f.readlines()
        with open(commit_msg_file, "wb") as f:
            for line in lines:
                if line[:2] == b"# ":
                    continue
                if not line.strip():
                    continue
                f.write(line.strip() + b"\n")
                push_allow = True
    except Exception as e:
        safe_print(f"[Error]: Failed to process commit message file - {str(e)}")
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)
    if not push_allow:
        safe_print(
            f"[Error]: Commit message file '{original_commit_file}' is empty (comments/blank lines filtered)"
        )
        os.remove(commit_msg_file)
        sys.exit(1)

    # Get all uncommitted files (modified + untracked)
    modified_files, untracked_files = get_uncommitted_files()
    safe_print(
        f"[Info]: Detected {len(modified_files)} modified files, {len(untracked_files)} untracked files"
    )

    # Collect all files to commit (with size info)
    all_files = []
    # Add modified files with size
    for file in modified_files:
        file_size = get_file_size(file)
        all_files.append((file, file_size))
    # Add untracked files (filtering oversize ones)
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"[Warning]: File '{file}' is {file_size/1024/1024:.2f}MB (exceeds 500MB). Skipped."
            )
            continue
        all_files.append((file, file_size))

    # If no files to commit, exit
    if not all_files:
        safe_print("[Info]: No files to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)

    # Calculate total size and sort files by size
    total_size = sum(size for _, size in all_files)
    all_files.sort(key=lambda x: x[1])  # Sort by size (smallest first)
    safe_print(
        f"[Info]: Total files to commit: {len(all_files)} (total size: {total_size/1024/1024:.2f}MB)"
    )

    # Commit logic: one batch if total size <= 500MB, else multiple batches
    if total_size <= MAX_BATCH_SIZE:
        safe_print(
            f"[Committing]: All files (total size {total_size/1024/1024:.2f}MB) will be committed in one batch..."
        )
        files_to_commit = [file for file, _ in all_files]
        if not commit_and_push(files_to_commit, commit_msg_file):
            safe_print("[Error]: Failed to commit files. Exiting.")
            os.remove(commit_msg_file)
            sys.exit(1)
    else:
        safe_print(
            f"[Committing]: Total size exceeds 500MB - starting batch commits..."
        )
        current_batch = []
        current_batch_size = 0

        for file, file_size in all_files:
            if current_batch_size + file_size > MAX_BATCH_SIZE:
                safe_print(
                    f"\n[Committing]: Submitting current batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)..."
                )
                if not commit_and_push(current_batch, commit_msg_file):
                    safe_print("[Error]: Batch commit failed. Exiting.")
                    os.remove(commit_msg_file)
                    sys.exit(1)
                current_batch = []
                current_batch_size = 0

            current_batch.append(file)
            current_batch_size += file_size

        # Commit final batch
        if current_batch:
            safe_print(
                f"\n[Committing]: Submitting final batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)..."
            )
            if not commit_and_push(current_batch, commit_msg_file):
                safe_print("[Error]: Final batch commit failed. Exiting.")
                os.remove(commit_msg_file)
                sys.exit(1)

    # Cleanup and exit
    os.remove(commit_msg_file)
    safe_print("\n[Complete]: All files have been successfully committed and pushed!")


if __name__ == "__main__":
    main()
