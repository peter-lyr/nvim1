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

# Constant definitions
MAX_BATCH_SIZE = 500 * 1024 * 1024  # 500MB (max total size per batch)
MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024  # Max size per file: 500MB
MAX_RETRIES = 5  # Max retries for Git Push


def run_command(command):
    """Execute command directly, output to console in real-time. Return success status (True/False)."""
    print(f"[Executing command]: {command}")
    # Configure Git encoding environment variables (avoid garbled text)
    env_cmd = ""
    if os.name == "nt":  # Windows system
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
    else:  # Non-Windows system
        env_cmd = "GIT_COMMITTER_ENCODING=utf-8 GIT_AUTHOR_ENCODING=utf-8 "

    # Execute command (output shown in console directly)
    exit_code = os.system(f"{env_cmd}{command}")
    return exit_code == 0  # 0 = success, non-0 = failure


def get_command_output(command):
    """Only for commands needing output parsing (e.g., get file list). Return command output."""
    import tempfile

    # Create temp file to store output (for parsing only, no impact on console display)
    with tempfile.NamedTemporaryFile(mode="w+", delete=False, encoding="utf-8") as f:
        temp_file = f.name

    # Execute command and capture output
    env_cmd = ""
    if os.name == "nt":
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
    os.system(f'{env_cmd}{command} > "{temp_file}" 2>&1')

    # Read output content
    output = ""
    try:
        with open(temp_file, "r", encoding="utf-8") as f:
            output = f.read()
    except UnicodeDecodeError:
        with open(temp_file, "r", encoding="gbk") as f:
            output = f.read()
    finally:
        os.remove(temp_file)  # Clean up temp file
    return output


def get_file_size(file_path):
    """Get file size (in bytes). Return size value."""
    try:
        # Handle path encoding to avoid errors from special characters
        file_path = file_path.encode("utf-8", errors="replace").decode("utf-8")
        return os.path.getsize(file_path)
    except OSError as e:
        print(f"[Warning]: Failed to get size of file '{file_path}' - {str(e)}")
        return 0


def get_uncommitted_files():
    """Get lists of modified and untracked files. Return (modified_files, untracked_files)."""
    # Get modified files (needs output parsing)
    modified_output = get_command_output("git diff --name-only")
    modified_files = [f.strip() for f in modified_output.splitlines() if f.strip()]

    # Get untracked files (needs output parsing)
    untracked_output = get_command_output("git ls-files --others --exclude-standard")
    untracked_files = [f.strip() for f in untracked_output.splitlines() if f.strip()]

    return modified_files, untracked_files


def commit_and_push(files, commit_msg_file):
    """Commit specified files and push with retry mechanism. Return success status (True/False)."""
    if not files:
        print("[Info]: No files need to be committed")
        return True

    # 1. Git Add: Add files (output shown directly)
    files_quoted = [f'"{f}"' for f in files]  # Handle filenames with spaces
    add_cmd = f"git add {' '.join(files_quoted)}"
    if not run_command(add_cmd):
        print("[Error]: Failed to add files")
        return False

    # 2. Git Commit: Commit files (output shown directly)
    commit_cmd = f'git commit -F "{commit_msg_file}"'
    if not run_command(commit_cmd):
        print("[Error]: Failed to commit files")
        return False

    print(f"[Success]: Successfully committed {len(files)} files")

    # 3. Git Push: Push with retry (output shown directly)
    for retry in range(MAX_RETRIES):
        print(f"[Pushing]: Attempt {retry+1}/{MAX_RETRIES}...")
        push_cmd = "git push"
        if run_command(push_cmd):
            print("[Success]: Push completed successfully")
            return True
        print(f"[Error]: Attempt {retry+1} failed")
        if retry < MAX_RETRIES - 1:
            print("[Waiting]: Retrying in 2 seconds...")
            time.sleep(2)

    print(f"[Error]: Maximum retries ({MAX_RETRIES}) reached. Push failed.")
    return False


def main():
    # Initialize: Force console encoding to UTF-8 (Windows)
    if os.name == "nt":
        # Execute chcp 65001 and verify encoding (avoid switch failure)
        os.system("chcp 65001 > nul")
        # Additional env var to enforce UTF-8 output
        os.environ["PYTHONIOENCODING"] = "utf-8"

    # 1. Check command line arguments
    if len(sys.argv) < 2:
        print(
            "[Error]: Missing argument! Usage: python git_batch_commit.py commit_message_file.txt"
        )
        sys.exit(1)
    original_commit_file = sys.argv[1]

    # 2. Process commit message file (filter comments and blank lines)
    if not os.path.exists(original_commit_file):
        print(f"[Error]: Commit message file '{original_commit_file}' does not exist")
        sys.exit(1)

    commit_msg_file = f"{original_commit_file}.tmp"  # Temp commit file
    push_allow = False
    try:
        with open(original_commit_file, "rb") as f:
            lines = f.readlines()
        with open(commit_msg_file, "wb") as f:
            for line in lines:
                if line[:2] == b"# ":  # Skip comment lines (starting with #)
                    continue
                if not line.strip():  # Skip blank lines
                    continue
                # Ensure content is UTF-8 encoded to avoid special character issues
                f.write(line.strip() + b"\n")
                push_allow = True
    except Exception as e:
        print(f"[Error]: Failed to process commit message file - {str(e)}")
        # Clean up temp file if it exists
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)

    if not push_allow:
        print(
            f"[Error]: Commit message file '{original_commit_file}' is empty (comments/blank lines filtered)"
        )
        os.remove(commit_msg_file)
        sys.exit(1)

    # 3. Get list of uncommitted files
    modified_files, untracked_files = get_uncommitted_files()
    print(
        f"[Info]: Detected {len(modified_files)} modified files, {len(untracked_files)} untracked files"
    )

    # 4. Commit modified files first
    if modified_files:
        print(
            f"\n[Committing]: Starting to commit {len(modified_files)} modified files..."
        )
        if not commit_and_push(modified_files, commit_msg_file):
            print("[Error]: Failed to commit modified files. Exiting.")
            os.remove(commit_msg_file)
            sys.exit(1)

    # 5. Handle untracked files (exit if none)
    if not untracked_files:
        print("\n[Info]: No untracked files to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)

    # 6. Filter untracked files (skip files over 500MB)
    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(
                f"[Warning]: File '{file}' is {file_size/1024/1024:.2f}MB (exceeds 500MB). Skipped."
            )
            continue
        filtered_files.append((file, file_size))

    # Sort files by size (ascending)
    filtered_files.sort(key=lambda x: x[1])
    print(
        f"\n[Info]: {len(filtered_files)} untracked files remaining after filtering (sorted by size)"
    )

    # 7. Commit untracked files in batches
    current_batch = []
    current_batch_size = 0  # Total size of current batch (bytes)

    for file, file_size in filtered_files:
        # Submit current batch if adding new file exceeds max batch size
        if current_batch_size + file_size > MAX_BATCH_SIZE:
            print(
                f"\n[Committing]: Submitting current batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)..."
            )
            if not commit_and_push(current_batch, commit_msg_file):
                print("[Error]: Batch commit failed. Exiting.")
                os.remove(commit_msg_file)
                sys.exit(1)
            # Reset batch
            current_batch = []
            current_batch_size = 0

        current_batch.append(file)
        current_batch_size += file_size

    # Commit the final batch (if any)
    if current_batch:
        print(
            f"\n[Committing]: Submitting final batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)..."
        )
        if not commit_and_push(current_batch, commit_msg_file):
            print("[Error]: Final batch commit failed. Exiting.")
            os.remove(commit_msg_file)
            sys.exit(1)

    # 8. Clean up temp file and exit
    os.remove(commit_msg_file)
    print("\n[Complete]: All files have been successfully committed and pushed!")


if __name__ == "__main__":
    main()
