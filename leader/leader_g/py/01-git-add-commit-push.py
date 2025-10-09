import os
import sys
import time
import tempfile

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024
MAX_RETRIES = 5


def run_command(command):
    """Execute command directly, output to console in real-time. Return success status (True/False)."""
    print(f"[Executing command]: {command}")
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
    """Only for commands needing output parsing (e.g., get file list). Return command output."""
    with tempfile.NamedTemporaryFile(mode="w+", delete=False, encoding="utf-8") as f:
        temp_file = f.name
    env_cmd = ""
    if os.name == "nt":
        env_cmd = (
            "set GIT_COMMITTER_ENCODING=utf-8 && set GIT_AUTHOR_ENCODING=utf-8 && "
        )
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
        file_path = file_path.encode("utf-8", errors="replace").decode("utf-8")
        return os.path.getsize(file_path)
    except OSError as e:
        print(f"[Warning]: Failed to get size of file '{file_path}' - {str(e)}")
        return 0


def get_uncommitted_files():
    """Get lists of modified and untracked files. Return (modified_files, untracked_files)."""
    modified_output = get_command_output("git diff --name-only")
    modified_files = [f.strip() for f in modified_output.splitlines() if f.strip()]
    untracked_output = get_command_output("git ls-files --others --exclude-standard")
    untracked_files = [f.strip() for f in untracked_output.splitlines() if f.strip()]
    return modified_files, untracked_files


def commit_and_push(files, commit_msg_file):
    """Commit specified files and push with retry mechanism. Return success status (True/False)."""
    if not files:
        print("[Info]: No files need to be committed")
        return True
    files_quoted = [f'"{f}"' for f in files]
    add_cmd = f"git add {' '.join(files_quoted)}"
    if not run_command(add_cmd):
        print("[Error]: Failed to add files")
        return False
    commit_cmd = f'git commit -F "{commit_msg_file}"'
    if not run_command(commit_cmd):
        print("[Error]: Failed to commit files")
        return False
    print(f"[Success]: Successfully committed {len(files)} files")
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
    if os.name == "nt":
        os.system("chcp 65001 > nul")
        os.environ["PYTHONIOENCODING"] = "utf-8"
    if len(sys.argv) < 2:
        print(
            "[Error]: Missing argument! Usage: python git_batch_commit.py commit_message_file.txt"
        )
        sys.exit(1)
    original_commit_file = sys.argv[1]
    if not os.path.exists(original_commit_file):
        print(f"[Error]: Commit message file '{original_commit_file}' does not exist")
        sys.exit(1)
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
        print(f"[Error]: Failed to process commit message file - {str(e)}")
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)
    if not push_allow:
        print(
            f"[Error]: Commit message file '{original_commit_file}' is empty (comments/blank lines filtered)"
        )
        os.remove(commit_msg_file)
        sys.exit(1)
    modified_files, untracked_files = get_uncommitted_files()
    print(
        f"[Info]: Detected {len(modified_files)} modified files, {len(untracked_files)} untracked files"
    )
    if modified_files:
        print(
            f"\n[Committing]: Starting to commit {len(modified_files)} modified files..."
        )
        if not commit_and_push(modified_files, commit_msg_file):
            print("[Error]: Failed to commit modified files. Exiting.")
            os.remove(commit_msg_file)
            sys.exit(1)
    if not untracked_files:
        print("\n[Info]: No untracked files to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)
    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(
                f"[Warning]: File '{file}' is {file_size/1024/1024:.2f}MB (exceeds 500MB). Skipped."
            )
            continue
        filtered_files.append((file, file_size))
    filtered_files.sort(key=lambda x: x[1])
    print(
        f"\n[Info]: {len(filtered_files)} untracked files remaining after filtering (sorted by size)"
    )
    current_batch = []
    current_batch_size = 0
    for file, file_size in filtered_files:
        if current_batch_size + file_size > MAX_BATCH_SIZE:
            print(
                f"\n[Committing]: Submitting current batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)..."
            )
            if not commit_and_push(current_batch, commit_msg_file):
                print("[Error]: Batch commit failed. Exiting.")
                os.remove(commit_msg_file)
                sys.exit(1)
            current_batch = []
            current_batch_size = 0
        current_batch.append(file)
        current_batch_size += file_size
    if current_batch:
        print(
            f"\n[Committing]: Submitting final batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)..."
        )
        if not commit_and_push(current_batch, commit_msg_file):
            print("[Error]: Final batch commit failed. Exiting.")
            os.remove(commit_msg_file)
            sys.exit(1)
    os.remove(commit_msg_file)
    print("\n[Complete]: All files have been successfully committed and pushed!")


if __name__ == "__main__":
    main()
