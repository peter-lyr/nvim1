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


def ultra_clean(text):
    """终极清理函数 - 使用简单直接的方法"""
    if not isinstance(text, str):
        text = str(text)

    # 直接替换所有已知的控制序列
    sequences_to_remove = [
        # 私有模式序列
        "\x1b[?9001h",
        "\x1b[?9001l",
        "\x1b[?1004h",
        "\x1b[?1004l",
        "\x1b[?25h",
        "\x1b[?25l",
        # 屏幕控制序列
        "\x1b[2J",
        "\x1b[H",
        "\x1b[m",
        # 窗口标题序列
        "\x1b]0;",
        "\x07",
    ]

    for seq in sequences_to_remove:
        if seq in text:
            print(f"<<{seq}>> is in <<{text}>>")
        else:
            print(f"<<{seq}>> is not in <<{text}>>")
        text = text.replace(seq, "")

    # 移除所有控制字符（除了换行和制表符）
    cleaned = ""
    for char in text:
        if char == "\n" or char == "\t" or (ord(char) >= 32 and ord(char) != 127):
            cleaned += char

    # 清理空白
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    cleaned = re.sub(r" +", " ", cleaned)

    return cleaned


def safe_quote_path(path):
    """安全引用路径"""
    if re.search(r'[\s，,()"]', path):
        return f'"{path.replace('"', '\\"')}"'
    return path


def safe_print(text):
    """安全打印函数"""
    try:
        cleaned_text = ultra_clean(text)
        if cleaned_text.strip():
            print(cleaned_text, flush=True)
    except Exception as e:
        error_text = f"[Error in safe_print]: {str(e)}"
        cleaned_error = ultra_clean(error_text)
        print(cleaned_error, flush=True)


def get_git_env():
    """Git环境设置"""
    env = os.environ.copy()
    env["GIT_COMMITTER_ENCODING"] = "utf-8"
    env["GIT_AUTHOR_ENCODING"] = "utf-8"
    env["LANG"] = "zh_CN.UTF-8"
    env["PYTHONIOENCODING"] = "utf-8"
    env["LC_ALL"] = "zh_CN.UTF-8"
    # 禁用所有可能的控制序列
    env["TERM"] = "dumb"
    env["GIT_CONFIG_NOSYSTEM"] = "1"
    env["GIT_PAGER"] = "cat"
    env["PAGER"] = "cat"
    return env


def run_command(cmd, cwd=None, capture_output=False):
    """执行命令"""
    original_cwd = os.getcwd()
    output = ""
    try:
        if cwd:
            os.chdir(cwd)
            safe_print(f"[Working directory]: {cwd}")

        safe_print(f"[Executing command]: {ultra_clean(cmd)}")
        env = get_git_env()

        if capture_output:
            # 使用subprocess直接捕获输出
            process = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=cwd,
                env=env,
                bufsize=1,
                universal_newlines=True,
                encoding="utf-8",
                errors="replace",
            )

            output_lines = []
            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    cleaned_line = ultra_clean(line)
                    if cleaned_line.strip():
                        output_lines.append(cleaned_line)

            output = "\n".join(output_lines)
            return process.returncode == 0, output
        else:
            # 实时输出
            process = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=cwd,
                env=env,
                bufsize=1,
                universal_newlines=True,
                encoding="utf-8",
                errors="replace",
            )

            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    cleaned_line = ultra_clean(line)
                    if cleaned_line.strip():
                        print(cleaned_line, flush=True)

            return process.returncode == 0, ""

    except Exception as e:
        err_msg = ultra_clean(str(e))
        safe_print(f"[Error] Command failed: {err_msg}")
        return False, err_msg
    finally:
        if cwd:
            os.chdir(original_cwd)


# 其他函数保持不变，只需将deep_clean替换为ultra_clean
def get_git_submodule_paths(git_root):
    """获取子仓库路径"""
    if not git_root:
        return []
    cmd = "git submodule status --recursive"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success or not output:
        return []

    submodule_abs_paths = []
    for line in re.split(r"[\r\n]+", output):
        line = ultra_clean(line).strip()
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
    """获取修改的子仓库"""
    if not git_root:
        return []
    cmd = "git submodule status --recursive"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success or not output:
        return []

    modified_submodules = []
    for line in re.split(r"[\r\n]+", output):
        line = ultra_clean(line).strip()
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
        err_msg = ultra_clean(str(e))
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
    # 清理命令行参数中的控制字符
    clean_args = [ultra_clean(arg) for arg in sys.argv]
    sys.argv = clean_args

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
            lines = [ultra_clean(line).replace("\r", "") for line in f.readlines()]
        with open(commit_msg_file, "w", encoding="utf-8") as f:
            for line in lines:
                if line.strip().startswith("#") or not line.strip():
                    continue
                f.write(f"{line.strip()}\n")
                push_allow = True
    except Exception as e:
        safe_print(f"[Error]: Process commit file failed - {ultra_clean(str(e))}")
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

    # 执行提交和推送
    result = commit_and_push(filtered_normal, modified_submodules, commit_msg_file)

    # 清理临时文件
    if os.path.exists(commit_msg_file):
        os.remove(commit_msg_file)

    # 最终输出
    if result:
        final_msg = "[Complete]: All content committed and pushed successfully!"
        print(ultra_clean(final_msg), flush=True)
    else:
        final_msg = "[Error]: Commit & Push failed"
        print(ultra_clean(final_msg), flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
