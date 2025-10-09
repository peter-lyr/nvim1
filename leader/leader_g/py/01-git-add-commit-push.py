import os
import sys
import time
import tempfile

sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024
MAX_RETRIES = 5


def safe_print(text):
    """适配Neovim-Qt，清理^M字符（\r残留），避免换行符乱码"""
    try:
        print(text, flush=True)
    except Exception as e:
        text_encoded = text.encode("utf-8", errors="replace").decode("utf-8")
        text_clean = text_encoded.rstrip("\r\n").rstrip("\n")
        print(text_clean, flush=True)


def get_git_env():
    """强制Git输出UTF-8的环境变量（核心修复路径乱码）"""
    env = os.environ.copy()
    env["GIT_COMMITTER_ENCODING"] = "utf-8"
    env["GIT_AUTHOR_ENCODING"] = "utf-8"
    env["LANG"] = "en_US.UTF-8"
    env["PYTHONIOENCODING"] = "utf-8"
    return env


def run_command(command):
    """执行命令，强制Git环境为UTF-8，输出适配Neovim"""
    safe_print(f"[Executing command]: {command}")
    env = get_git_env()
    if os.name == "nt":
        env_cmd = " && ".join(
            [f"set {k}={v}" for k, v in env.items() if k not in os.environ]
        )
        full_cmd = f"{env_cmd} && {command}" if env_cmd else command
    else:
        env_cmd = " ; ".join(
            [f"export {k}={v}" for k, v in env.items() if k not in os.environ]
        )
        full_cmd = f"{env_cmd} ; {command}" if env_cmd else command
    exit_code = os.system(full_cmd)
    return exit_code == 0


def get_command_output(command):
    """获取Git命令输出，清理\r字符，避免^M残留"""
    env = get_git_env()
    with tempfile.NamedTemporaryFile(
        mode="w+", delete=False, encoding="utf-8", newline="\n"
    ) as f:
        temp_file = f.name
    if os.name == "nt":
        env_cmd = " && ".join(
            [f"set {k}={v}" for k, v in env.items() if k not in os.environ]
        )
        full_cmd = (
            f'{env_cmd} && {command} > "{temp_file}" 2>&1'
            if env_cmd
            else f'{command} > "{temp_file}" 2>&1'
        )
    else:
        env_cmd = " ; ".join(
            [f"export {k}={v}" for k, v in env.items() if k not in os.environ]
        )
        full_cmd = (
            f'{env_cmd} ; {command} > "{temp_file}" 2>&1'
            if env_cmd
            else f'{command} > "{temp_file}" 2>&1'
        )
    safe_print(f"[Parsing output]: {command}")
    os.system(full_cmd)
    output = ""
    try:
        with open(temp_file, "r", encoding="utf-8", newline="") as f:
            output = f.read().replace("\r", "")
    finally:
        os.remove(temp_file)
    return output


def get_file_size(file_path):
    """获取文件大小（处理UTF-8路径，避免找不到文件）"""
    try:
        file_path = file_path.strip().replace("\r", "")
        file_path = os.path.abspath(file_path)
        if not os.path.exists(file_path):
            safe_print(f"[Warning]: File not found (check path encoding): {file_path}")
            return 0
        return os.path.getsize(file_path)
    except OSError as e:
        safe_print(f"[Warning]: Failed to get size of file '{file_path}' - {str(e)}")
        return 0


def get_uncommitted_files():
    """获取未提交文件，清理路径中的\r字符"""
    modified_output = get_command_output("git diff --name-only")
    modified_files = [
        f.strip().replace("\r", "") for f in modified_output.splitlines() if f.strip()
    ]
    untracked_output = get_command_output("git ls-files --others --exclude-standard")
    untracked_files = [
        f.strip().replace("\r", "") for f in untracked_output.splitlines() if f.strip()
    ]
    valid_modified = [f for f in modified_files if os.path.exists(os.path.abspath(f))]
    invalid_modified = set(modified_files) - set(valid_modified)
    if invalid_modified:
        safe_print("[Warning]: Invalid modified file paths (encoding issue):")
        for modified in invalid_modified:
            safe_print(f" {modified}")
    valid_untracked = [f for f in untracked_files if os.path.exists(os.path.abspath(f))]
    invalid_untracked = set(untracked_files) - set(valid_untracked)
    if invalid_untracked:
        safe_print("[Warning]: Invalid untracked file paths (encoding issue):")
        for untracked in invalid_untracked:
            safe_print(f" {untracked}")
    return valid_modified, valid_untracked


def commit_and_push(files, commit_msg_file):
    """提交文件，清理路径中的\r字符"""
    if not files:
        safe_print("[Info]: No files need to be committed")
        return True
    files_clean = [f.replace("\r", "") for f in files]
    files_quoted = [f'"{os.path.abspath(f)}"' for f in files_clean]
    add_cmd = f"git add {' '.join(files_quoted)}"
    if not run_command(add_cmd):
        safe_print("[Error]: Failed to add files")
        return False
    commit_msg_file_clean = commit_msg_file.replace("\r", "")
    commit_cmd = f'git commit -F "{os.path.abspath(commit_msg_file_clean)}"'
    if not run_command(commit_cmd):
        safe_print("[Error]: Failed to commit files")
        return False
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
    if len(sys.argv) < 2:
        safe_print(
            "[Error]: Missing argument! Usage: python git_batch_commit.py commit_message_file.txt"
        )
        sys.exit(1)
    original_commit_file = sys.argv[1].replace("\r", "")
    original_commit_file = os.path.abspath(original_commit_file)
    if not os.path.exists(original_commit_file):
        safe_print(f"[Error]: Commit message file not found: '{original_commit_file}'")
        sys.exit(1)
    commit_msg_file = f"{original_commit_file}.tmp"
    push_allow = False
    try:
        with open(original_commit_file, "r", encoding="utf-8", newline="") as f:
            lines = [line.replace("\r", "") for line in f.readlines()]
        with open(commit_msg_file, "w", encoding="utf-8", newline="\n") as f:
            for line in lines:
                line_stripped = line.strip()
                if line_stripped.startswith("#") or not line_stripped:
                    continue
                f.write(f"{line_stripped}\n")
                push_allow = True
    except Exception as e:
        safe_print(f"[Error]: Failed to process commit message file - {str(e)}")
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)
    if not push_allow:
        safe_print(
            f"[Error]: Commit message file is empty (comments/blank lines filtered): {original_commit_file}"
        )
        os.remove(commit_msg_file)
        sys.exit(1)
    modified_files, untracked_files = get_uncommitted_files()
    safe_print(
        f"[Info]: Detected {len(modified_files)} valid modified files, {len(untracked_files)} valid untracked files"
    )
    all_files = []
    for file in modified_files:
        file_size = get_file_size(file)
        all_files.append((file, file_size))
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"[Warning]: File exceeds 500MB (skipped): '{file}' ({file_size/1024/1024:.2f}MB)"
            )
            continue
        all_files.append((file, file_size))
    if not all_files:
        safe_print("[Info]: No valid files to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)
    total_size = sum(size for _, size in all_files)
    all_files.sort(key=lambda x: x[1])
    safe_print(
        f"[Info]: Total valid files to commit: {len(all_files)} (total size: {total_size/1024/1024:.2f}MB)"
    )
    if total_size <= MAX_BATCH_SIZE:
        safe_print(
            f"[Committing]: All files in one batch (total size: {total_size/1024/1024:.2f}MB)"
        )
        files_to_commit = [file for file, _ in all_files]
        if not commit_and_push(files_to_commit, commit_msg_file):
            safe_print("[Error]: Failed to commit files. Exiting.")
            os.remove(commit_msg_file)
            sys.exit(1)
    else:
        safe_print(f"[Committing]: Batch mode (total size exceeds 500MB)")
        current_batch = []
        current_batch_size = 0
        for file, file_size in all_files:
            if current_batch_size + file_size > MAX_BATCH_SIZE:
                safe_print(
                    f"\n[Committing]: Current batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)"
                )
                if not commit_and_push(current_batch, commit_msg_file):
                    safe_print("[Error]: Batch commit failed. Exiting.")
                    os.remove(commit_msg_file)
                    sys.exit(1)
                current_batch = []
                current_batch_size = 0
            current_batch.append(file)
            current_batch_size += file_size
        if current_batch:
            safe_print(
                f"\n[Committing]: Final batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)"
            )
            if not commit_and_push(current_batch, commit_msg_file):
                safe_print("[Error]: Final batch commit failed. Exiting.")
                os.remove(commit_msg_file)
                sys.exit(1)
    os.remove(commit_msg_file)
    safe_print("\n[Complete]: All files have been successfully committed and pushed!")


if __name__ == "__main__":
    main()
