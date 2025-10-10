import os
import sys
import time
import tempfile
import re  # 新增：用于匹配控制序列

sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 100 * 1024 * 1024
MAX_RETRIES = 5

cur_working_directory = ""


def strip_control_chars(text):
    """核心：过滤所有终端控制序列和特殊字符
    覆盖场景：
    - ANSI 转义码（如 ^[[?25h、^[[2J、^[[m）
    - ASCII 控制字符（如 ^G（BEL）、^H（退格）等）
    - 终端标题序列（如 ^[]0;...^G）
    """
    if not isinstance(text, str):
        return text
    # 1. 过滤 ANSI 转义序列（以 ESC 开头，常见格式）
    # 匹配 ^[[...m（颜色/格式）、^[[...h/l（光标）、^[[...J（清屏）、^[[...H（光标位置）
    text = re.sub(r"\x1B\[[0-9;?]*[mKhlHJ]", "", text)
    # 2. 过滤终端标题序列（^[]0;内容^G）
    text = re.sub(r"\x1B\]0;.*?\x07", "", text)
    # 3. 过滤单个 ASCII 控制字符（0-31 及 127 号字符，除了换行\n、回车\r、制表符\t）
    text = re.sub(r"[\x00-\x06\x08-\x1F\x7F]", "", text)
    return text


def safe_print(text):
    """打印前先过滤控制字符"""
    try:
        # 新增：打印前过滤控制字符
        cleaned_text = strip_control_chars(text)
        print(cleaned_text, flush=True)
    except:
        text_encoded = text.encode("utf-8", errors="replace").decode("utf-8")
        cleaned_text = strip_control_chars(text_encoded)
        print(cleaned_text, flush=True)


def get_git_env():
    """强制Git输出UTF-8的环境变量（核心修复路径乱码）"""
    env = os.environ.copy()
    env["GIT_COMMITTER_ENCODING"] = "utf-8"
    env["GIT_AUTHOR_ENCODING"] = "utf-8"
    env["LANG"] = "en_US.UTF-8"
    env["PYTHONIOENCODING"] = "utf-8"
    return env


def run_command(cmd, cwd=None):
    """执行命令，强制Git环境为UTF-8，支持指定工作目录，输出适配Neovim"""
    global cur_working_directory
    original_cwd = os.getcwd()
    try:
        if cwd:
            os.chdir(cwd)
            if cur_working_directory != cwd:
                cur_working_directory = cwd
                safe_print(f"[Working directory]: {cwd}")
        # 打印命令时无需过滤（cmd本身无控制字符）
        safe_print(f"[Executing command]: {cmd}")
        env = get_git_env()
        if os.name == "nt":
            env_cmd = " && ".join(
                [f"set {k}={v}" for k, v in env.items() if k not in os.environ]
            )
        else:
            env_cmd = " ; ".join(
                [f"export {k}={v}" for k, v in env.items() if k not in os.environ]
            )
        full_cmd = (
            f"{env_cmd} && {cmd}"
            if env_cmd
            else cmd if os.name == "nt" else f"{env_cmd} ; {cmd}" if env_cmd else cmd
        )
        exit_code = os.system(full_cmd)
        return exit_code == 0
    except Exception as e:
        # 异常信息也需过滤
        safe_print(f"[Error] Command execution failed: {strip_control_chars(str(e))}")
        return False
    finally:
        if cwd:
            os.chdir(original_cwd)


def get_uncommitted_files():
    """获取未提交文件（含删除文件！），清理路径中的\r字符"""
    # 命令输出先过滤控制字符，再处理路径
    modified_output = strip_control_chars(
        get_command_output("git diff --name-only --diff-filter=ADM")
    )
    modified_files = [
        f.strip().replace("\r", "") for f in modified_output.splitlines() if f.strip()
    ]
    untracked_output = strip_control_chars(
        get_command_output("git ls-files --others --exclude-standard")
    )
    untracked_files = [
        f.strip().replace("\r", "") for f in untracked_output.splitlines() if f.strip()
    ]
    valid_modified = []
    invalid_modified = []
    for file in modified_files:
        file_abspath = os.path.abspath(file)
        if os.path.exists(file_abspath) or is_file_deleted_by_git(file):
            valid_modified.append(file)
        else:
            invalid_modified.append(file)
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


def is_file_deleted_by_git(file_path):
    """判断文件是否被Git标记为删除（解决删除文件无法检测的问题）"""
    command = f'git diff --name-only --diff-filter=D -- "{file_path}"'
    # 输出过滤控制字符后再比较
    output = strip_control_chars(get_command_output(command))
    return output.strip() == file_path.strip()


def get_command_output(command):
    """获取Git命令输出，清理\r字符和控制字符，避免^M/^G残留"""
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
    if not command.startswith("git diff --name-only --diff-filter=D"):
        safe_print(f"[Parsing output]: {command}")
    os.system(full_cmd)
    output = ""
    try:
        with open(temp_file, "r", encoding="utf-8", newline="") as f:
            output = f.read()
        # 先过滤控制字符，再清理\r
        output = strip_control_chars(output).replace("\r", "")
    finally:
        os.remove(temp_file)
    return output


def get_file_size(file_path):
    """获取文件大小（删除文件直接返回0，无需报错）"""
    try:
        file_path = file_path.strip().replace("\r", "")
        file_abspath = os.path.abspath(file_path)
        if is_file_deleted_by_git(file_path):
            return 0
        if not os.path.exists(file_abspath):
            safe_print(f"[Warning]: File not found (not deleted by Git): {file_path}")
            return 0
        return os.path.getsize(file_abspath)
    except OSError as e:
        # 异常信息过滤控制字符
        safe_print(
            f"[Warning]: Failed to get size of file '{file_path}' - {strip_control_chars(str(e))}"
        )
        return 0


def find_git_root(start_path=None):
    """查找Git仓库的根目录（包含.git的目录）"""
    current_path = start_path or os.getcwd()
    while True:
        git_dir = os.path.join(current_path, ".git")
        if os.path.exists(git_dir) and os.path.isdir(git_dir):
            return current_path
        parent_path = os.path.dirname(current_path)
        if parent_path == current_path:
            return None
        current_path = parent_path


def commit_and_push(files, commit_msg_file):
    """提交文件（支持删除文件，使用相对路径）"""
    if not files:
        safe_print("[Info]: No files need to be committed")
        return True
    git_root = find_git_root()
    if not git_root:
        safe_print("[Error]: Could not find Git repository root (.git directory)")
        return False
    files_clean = [f.replace("\r", "") for f in files]
    try:
        files_relative = [
            os.path.relpath(os.path.abspath(f), git_root) for f in files_clean
        ]
        files_quoted = [f'"{f}"' for f in files_relative]
    except ValueError as e:
        safe_print(
            f"[Error]: Failed to calculate relative paths: {strip_control_chars(str(e))}"
        )
        return False
    add_cmd = f"git add {' '.join(files_quoted)}"
    if not run_command(add_cmd, cwd=git_root):
        safe_print("[Error]: Failed to add files (including deleted files)")
        return False
    commit_msg_file_clean = commit_msg_file.replace("\r", "")
    commit_msg_abs = os.path.abspath(commit_msg_file_clean)
    commit_cmd = f'git commit -F "{commit_msg_abs}"'
    if not run_command(commit_cmd, cwd=git_root):
        safe_print("[Error]: Failed to commit files (including deleted files)")
        return False
    safe_print(
        f"[Success]: Successfully committed {len(files)} files (including deleted)"
    )
    for retry in range(MAX_RETRIES):
        safe_print(f"[Pushing]: Attempt {retry+1}/{MAX_RETRIES}...")
        push_cmd = "git push"
        if run_command(push_cmd, cwd=git_root):
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
        safe_print(
            f"[Error]: Failed to process commit message file - {strip_control_chars(str(e))}"
        )
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
        f"[Info]: Detected {len(modified_files)} valid modified/deleted files, {len(untracked_files)} valid untracked files"
    )
    all_files = []
    for file in modified_files:
        file_size = get_file_size(file)
        all_files.append((file, file_size))
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"[Warning]: File exceeds 100MB (skipped): '{file}' ({file_size/1024/1024:.2f}MB)"
            )
            continue
        all_files.append((file, file_size))
    if not all_files:
        safe_print("[Info]: No valid files to commit (including deleted). Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)
    total_size = sum(size for _, size in all_files)
    all_files.sort(key=lambda x: x[1])
    safe_print(
        f"[Info]: Total valid files to commit: {len(all_files)} (total size: {total_size/1024/1024:.2f}MB, including deleted files)"
    )
    if total_size <= MAX_BATCH_SIZE:
        safe_print(
            f"[Committing]: All files in one batch (total size: {total_size/1024/1024:.2f}MB, including deleted)"
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
                    f"[Committing]: Current batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)"
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
                f"[Committing]: Final batch ({len(current_batch)} files, {current_batch_size/1024/1024:.2f}MB)"
            )
            if not commit_and_push(current_batch, commit_msg_file):
                safe_print("[Error]: Final batch commit failed. Exiting.")
                os.remove(commit_msg_file)
                sys.exit(1)
    os.remove(commit_msg_file)
    safe_print(
        "[Complete]: All files (including deleted) have been successfully committed and pushed!"
    )


if __name__ == "__main__":
    main()
