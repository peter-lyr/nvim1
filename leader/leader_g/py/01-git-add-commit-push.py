import os
import sys
import time
import tempfile
import re
import subprocess

# 确保标准输出/错误使用UTF-8编码
sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 100 * 1024 * 1024
MAX_RETRIES = 5

cur_working_directory = ""


def strip_control_chars(text):
    """终极版控制字符过滤器，专门针对观察到的所有终端控制序列"""
    if not isinstance(text, str):
        return text

    # 1. 处理所有私有模式控制序列 (最常见的问题序列)
    # 匹配如[?9001h、[?1004l这类序列
    text = re.sub(r"\x1B\[\?\d+[hl]", "", text)

    # 2. 处理光标和屏幕控制序列
    # 匹配如[2J(清屏)、[H(光标归位)、[?25l(隐藏光标)、[?25h(显示光标)
    text = re.sub(r"\x1B\[\d+[JK]", "", text)
    text = re.sub(r"\x1B\[\?25[lh]", "", text)
    text = re.sub(r"\x1B\[H", "", text)

    # 3. 处理SGR(选择图形再现)序列，如[m(重置)
    text = re.sub(r"\x1B\[[\d;]*m", "", text)

    # 4. 处理OSC(操作系统命令)序列，如]0;...(设置窗口标题)
    text = re.sub(r"\x1B\]0;[^\x07]*\x07", "", text)

    # 5. 处理所有其他ESC开头的控制序列
    text = re.sub(r"\x1B[^\x40-\x7E]*[\x40-\x7E]", "", text)

    # 6. 移除所有ASCII控制字符(0-31, 127)和扩展控制字符(128-159)
    text = re.sub(r"[\x00-\x1F\x7F\x80-\x9F]", "", text)

    # 7. 清理可能的空行
    text = re.sub(r"\n\s*\n", "\n", text).strip()

    return text


def safe_quote_path(path):
    """安全引用路径（处理空格、中文逗号等）"""
    if re.search(r'[\s，,()"]', path):
        return f'"{path.replace('"', '\\"')}"'  # 转义路径中的双引号
    return path


def safe_print(text):
    """安全打印，确保所有输出经过多层过滤"""
    try:
        # 双重过滤确保安全
        cleaned_text = strip_control_chars(str(text))
        # 再次过滤以防万一
        cleaned_text = strip_control_chars(cleaned_text)
        if cleaned_text.strip():
            print(cleaned_text, flush=True)
    except Exception as e:
        error_text = f"[Error in safe_print]: {str(e)}"
        cleaned_error = strip_control_chars(error_text)
        print(cleaned_error, flush=True)


def get_git_env():
    """强制Git使用UTF-8编码（适配中文）"""
    env = os.environ.copy()
    env["GIT_COMMITTER_ENCODING"] = "utf-8"
    env["GIT_AUTHOR_ENCODING"] = "utf-8"
    env["LANG"] = "zh_CN.UTF-8"
    env["PYTHONIOENCODING"] = "utf-8"
    env["LC_ALL"] = "zh_CN.UTF-8"
    return env


def run_command(cmd, cwd=None, capture_output=False):
    """执行命令并全面过滤输出"""
    global cur_working_directory
    original_cwd = os.getcwd()
    output = ""
    try:
        if cwd:
            os.chdir(cwd)
            if cur_working_directory != cwd:
                cur_working_directory = cwd
                safe_print(f"[Working directory]: {cwd}")

        # 过滤命令中的控制字符后再打印
        safe_print(f"[Executing command]: {strip_control_chars(cmd)}")
        env = get_git_env()

        # 构建环境变量命令
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
            if (env_cmd and os.name == "nt")
            else f"{env_cmd} ; {cmd}" if (env_cmd and os.name != "nt") else cmd
        )

        # 捕获输出
        if capture_output:
            with tempfile.NamedTemporaryFile(
                mode="w+", delete=False, encoding="utf-8", newline=""
            ) as f:
                temp_file = f.name
            full_cmd += f" > {safe_quote_path(temp_file)} 2>&1"
            os.system(full_cmd)
            # 读取时过滤所有控制字符
            with open(
                temp_file, "r", encoding="utf-8", errors="replace", newline=""
            ) as f:
                output = strip_control_chars(f.read())
            os.remove(temp_file)
        else:
            # 使用subprocess确保兼容性
            process = subprocess.Popen(
                full_cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=cwd,
                env=env,
                bufsize=1,
            )

            # 逐行读取并过滤输出
            while True:
                line = process.stdout.readline()
                if not line:
                    break
                # 处理不同编码
                try:
                    line_str = line.decode("utf-8", errors="replace")
                except UnicodeDecodeError:
                    line_str = line.decode("gbk", errors="replace")  # 兼容Windows
                # 双重过滤
                cleaned_line = strip_control_chars(line_str)
                cleaned_line = strip_control_chars(cleaned_line)
                if cleaned_line.strip():
                    print(cleaned_line, flush=True)

            process.wait()
            if process.returncode != 0:
                return False, f"Command failed with exit code {process.returncode}"

        return True, output
    except Exception as e:
        err_msg = strip_control_chars(str(e))
        safe_print(f"[Error] Command failed: {err_msg}")
        return False, err_msg
    finally:
        if cwd:
            os.chdir(original_cwd)


# 以下函数保持不变
def get_git_submodule_paths(git_root):
    """获取子仓库路径（按行严格分割）"""
    if not git_root:
        return []
    cmd = "git submodule status --recursive"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success or not output:
        return []

    submodule_abs_paths = []
    for line in re.split(r"[\r\n]+", output):
        line = line.strip()
        if not line:
            continue
        parts = re.split(r"\s+", line, 2)
        if len(parts) >= 2:
            sm_rel_path = parts[1]
            sm_abs_path = os.path.abspath(os.path.join(git_root, sm_rel_path))
            submodule_abs_paths.append(sm_abs_path)
    return submodule_abs_paths


def filter_out_submodules(file_list, submodule_abs_paths, git_root):
    """过滤子仓库路径"""
    if not file_list or not submodule_abs_paths or not git_root:
        return file_list

    filtered_files = []
    for file in file_list:
        file_abs_path = os.path.abspath(os.path.join(git_root, file))
        is_submodule = False
        for sm_abs in submodule_abs_paths:
            if os.path.commonprefix([file_abs_path, sm_abs]) == sm_abs:
                is_submodule = True
                break
        if not is_submodule:
            filtered_files.append(file)
    return filtered_files


def get_git_submodule_modified(git_root):
    """获取修改的子仓库（按行分割）"""
    if not git_root:
        return []
    cmd = "git submodule status --recursive"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success or not output:
        return []

    modified_submodules = []
    for line in re.split(r"[\r\n]+", output):
        line = line.strip()
        if not line:
            continue
        if line.startswith(("+", "-")):
            parts = re.split(r"\s+", line, 2)
            if len(parts) >= 2:
                modified_submodules.append(parts[1])
    return modified_submodules


def handle_git_submodule(submodule_rel_path, git_root):
    """处理子仓库"""
    if not git_root or not submodule_rel_path:
        return False
    sm_abs = os.path.abspath(os.path.join(git_root, submodule_rel_path))
    sm_quoted = safe_quote_path(sm_abs)

    cmd_init = f"git submodule update --init {sm_quoted}"
    safe_print(f"[Submodule] Initializing: {submodule_rel_path}")
    success, _ = run_command(cmd_init, cwd=git_root)
    if not success:
        safe_print(f"[Error] Failed to initialize submodule: {submodule_rel_path}")
        return False

    cmd_add = f"git add {sm_quoted}"
    safe_print(f"[Submodule] Staging: {submodule_rel_path}")
    success, _ = run_command(cmd_add, cwd=git_root)
    if not success:
        safe_print(f"[Error] Failed to stage submodule: {submodule_rel_path}")
        return False
    return True


def get_uncommitted_files():
    """获取未提交文件"""
    git_root = find_git_root()
    if not git_root:
        safe_print("[Error]: Could not find Git repository root")
        return [], [], []

    submodule_abs_paths = get_git_submodule_paths(git_root)

    cmd_modified = "git diff --name-only --diff-filter=ADM"
    success, modified_output = run_command(
        cmd_modified, cwd=git_root, capture_output=True
    )
    cmd_untracked = "git ls-files --others --exclude-standard"
    success_untracked, untracked_output = run_command(
        cmd_untracked, cwd=git_root, capture_output=True
    )

    all_modified = [
        f.strip() for f in re.split(r"[\r\n]+", modified_output) if f.strip()
    ]
    all_untracked = [
        f.strip() for f in re.split(r"[\r\n]+", untracked_output) if f.strip()
    ]

    filtered_modified = filter_out_submodules(
        all_modified, submodule_abs_paths, git_root
    )
    filtered_untracked = filter_out_submodules(
        all_untracked, submodule_abs_paths, git_root
    )

    valid_normal = []
    invalid_normal = []
    for file_list in [filtered_modified, filtered_untracked]:
        for f in file_list:
            if not f:
                continue
            f_abs = os.path.abspath(os.path.join(git_root, f))
            if os.path.exists(f_abs) or is_file_deleted_by_git(f, git_root):
                valid_normal.append(f)
            else:
                invalid_normal.append(f)

    modified_submodules = get_git_submodule_modified(git_root)

    safe_print(f"[Debug]: Found {len(valid_normal)} valid normal files")
    safe_print(f"[Debug]: Found {len(modified_submodules)} modified submodules")
    if invalid_normal:
        safe_print("[Warning]: Invalid file paths (not exist or encoding issue):")
        for f in invalid_normal:
            safe_print(f"  {f}")

    return valid_normal, invalid_normal, modified_submodules


def is_file_deleted_by_git(file_rel_path, git_root):
    """判断文件是否被删除"""
    if not git_root or not file_rel_path:
        return False
    quoted_path = safe_quote_path(file_rel_path)
    cmd = f"git diff --name-only --diff-filter=D -- {quoted_path}"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    deleted_files = [f.strip() for f in re.split(r"[\r\n]+", output) if f.strip()]
    return file_rel_path in deleted_files


def get_file_size(file_rel_path, git_root):
    """获取文件大小"""
    if not git_root or not file_rel_path:
        return 0
    submodule_abs_paths = get_git_submodule_paths(git_root)
    file_abs = os.path.abspath(os.path.join(git_root, file_rel_path))
    for sm_abs in submodule_abs_paths:
        if os.path.commonprefix([file_abs, sm_abs]) == sm_abs:
            return 0

    try:
        if is_file_deleted_by_git(file_rel_path, git_root):
            return 0
        if not os.path.exists(file_abs):
            safe_print(f"[Warning]: File not found: {file_rel_path}")
            return 0
        return os.path.getsize(file_abs)
    except OSError as e:
        err_msg = strip_control_chars(str(e))
        safe_print(f"[Warning]: Failed to get size of '{file_rel_path}' - {err_msg}")
        return 0


def find_git_root(start_path=None):
    """查找Git根目录"""
    current_path = start_path or os.getcwd()
    while True:
        git_dir = os.path.join(current_path, ".git")
        if os.path.exists(git_dir) and os.path.isdir(git_dir):
            return current_path
        parent_path = os.path.dirname(current_path)
        if parent_path == current_path:
            return None
        current_path = parent_path


def commit_and_push(valid_normal, modified_submodules, commit_msg_file):
    """提交文件和子仓库"""
    git_root = find_git_root()
    if not git_root:
        safe_print("[Error]: Could not find Git repository root")
        return False

    if valid_normal:
        safe_print(f"[Info]: Staging {len(valid_normal)} normal files...")
        files_quoted = [
            safe_quote_path(os.path.join(git_root, f)) for f in valid_normal
        ]
        cmd_add = f"git add {' '.join(files_quoted)}"
        success, _ = run_command(cmd_add, cwd=git_root)
        if not success:
            safe_print("[Error]: Failed to stage normal files")
            return False

    if modified_submodules:
        safe_print(f"[Info]: Handling {len(modified_submodules)} submodules...")
        for sm_rel in modified_submodules:
            if not handle_git_submodule(sm_rel, git_root):
                return False

    commit_msg_abs = os.path.abspath(commit_msg_file)
    cmd_commit = f"git commit -F {safe_quote_path(commit_msg_abs)}"
    safe_print("[Info]: Committing changes...")
    success, _ = run_command(cmd_commit, cwd=git_root)
    if not success:
        safe_print("[Error]: Failed to commit changes")
        return False

    total = len(valid_normal) + len(modified_submodules)
    safe_print(f"[Success]: Committed {total} items (files + submodules)")
    for retry in range(MAX_RETRIES):
        safe_print(f"[Pushing]: Attempt {retry+1}/{MAX_RETRIES}...")
        cmd_push = "git push --recurse-submodules=on-demand"
        success, _ = run_command(cmd_push, cwd=git_root)
        if success:
            safe_print("[Success]: Push completed successfully")
            return True
        safe_print(f"[Error]: Push attempt {retry+1} failed")
        if retry < MAX_RETRIES - 1:
            time.sleep(2)

    safe_print(f"[Error]: Maximum retries ({MAX_RETRIES}) reached")
    return False


def main():
    if len(sys.argv) < 2:
        safe_print(
            "[Error]: Usage: python git_batch_commit.py <commit_message_file.txt>"
        )
        sys.exit(1)

    git_root = find_git_root()
    original_commit_file = os.path.abspath(sys.argv[1].replace("\r", ""))
    commit_msg_file = f"{original_commit_file}.tmp"
    push_allow = False

    if not os.path.exists(original_commit_file):
        safe_print(f"[Error]: Commit file not found: '{original_commit_file}'")
        sys.exit(1)
    try:
        with open(original_commit_file, "r", encoding="utf-8", errors="replace") as f:
            lines = [
                strip_control_chars(line).replace("\r", "") for line in f.readlines()
            ]
        with open(commit_msg_file, "w", encoding="utf-8") as f:
            for line in lines:
                if line.strip().startswith("#") or not line.strip():
                    continue
                f.write(f"{line.strip()}\n")
                push_allow = True
    except Exception as e:
        safe_print(
            f"[Error]: Process commit file failed - {strip_control_chars(str(e))}"
        )
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)
    if not push_allow:
        safe_print("[Error]: Commit message is empty (filtered comments/blank lines)")
        os.remove(commit_msg_file)
        sys.exit(1)

    valid_normal, _, modified_submodules = get_uncommitted_files()
    filtered_normal = []
    for f in valid_normal:
        file_size = get_file_size(f, git_root)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"[Warning]: File exceeds 100MB (skipped): '{f}' ({file_size/1024/1024:.2f}MB)"
            )
            continue
        filtered_normal.append(f)

    total = len(filtered_normal) + len(modified_submodules)
    if total == 0:
        safe_print("[Info]: No valid content to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)
    safe_print(
        f"[Info]: To commit: {len(filtered_normal)} files + {len(modified_submodules)} submodules"
    )

    if not commit_and_push(filtered_normal, modified_submodules, commit_msg_file):
        safe_print("[Error]: Commit & Push failed")
        os.remove(commit_msg_file)
        sys.exit(1)

    os.remove(commit_msg_file)
    safe_print("[Complete]: All content committed and pushed successfully!")


if __name__ == "__main__":
    main()
