import os
import sys
import time
import tempfile
import re

sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 100 * 1024 * 1024
MAX_RETRIES = 5

cur_working_directory = ""


def strip_control_chars(text):
    """过滤控制字符，保留中文特殊字符和换行符"""
    if not isinstance(text, str):
        return text
    # 仅过滤ANSI控制序列和ASCII不可见字符，保留换行符和中文符号
    text = re.sub(r"\x1B\[[0-9;?]*[mKhlHJ]", "", text)  # ANSI控制序列
    text = re.sub(r"\x1B\]0;.*?\x07", "", text)  # 终端标题序列
    text = re.sub(r"[^\x20-\x7E\xA0-\xFF\n\r]", "", text)  # 保留可见字符和换行
    return text


def safe_quote_path(path):
    """安全引用路径（处理空格、中文逗号等）"""
    if re.search(r'[\s，,()"]', path):
        return f'"{path.replace('"', '\\"')}"'  # 转义路径中的双引号
    return path


def safe_print(text):
    """安全打印（支持中文）"""
    try:
        cleaned_text = strip_control_chars(text)
        print(cleaned_text, flush=True)
    except:
        text_encoded = text.encode("utf-8", errors="replace").decode("utf-8")
        cleaned_text = strip_control_chars(text_encoded)
        print(cleaned_text, flush=True)


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
    """执行命令（确保输出正确捕获换行符）"""
    global cur_working_directory
    original_cwd = os.getcwd()
    output = ""
    try:
        if cwd:
            os.chdir(cwd)
            if cur_working_directory != cwd:
                cur_working_directory = cwd
                safe_print(f"[Working directory]: {cwd}")
        safe_print(f"[Executing command]: {cmd}")
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

        # 捕获输出（强制保留原始换行符）
        if capture_output:
            with tempfile.NamedTemporaryFile(
                mode="w+", delete=False, encoding="utf-8", newline=""
            ) as f:
                temp_file = f.name
            full_cmd += f" > {safe_quote_path(temp_file)} 2>&1"
            os.system(full_cmd)
            # 读取时保留原始换行符，避免自动转换
            with open(
                temp_file, "r", encoding="utf-8", errors="replace", newline=""
            ) as f:
                output = strip_control_chars(f.read())
            os.remove(temp_file)
        else:
            os.system(full_cmd)
        return True, output
    except Exception as e:
        err_msg = strip_control_chars(str(e))
        safe_print(f"[Error] Command failed: {err_msg}")
        return False, err_msg
    finally:
        if cwd:
            os.chdir(original_cwd)


def get_git_submodule_paths(git_root):
    """获取子仓库路径（按行严格分割）"""
    if not git_root:
        return []
    cmd = "git submodule status --recursive"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success or not output:
        return []

    submodule_abs_paths = []
    # 强制按换行符分割（兼容\n和\r\n）
    for line in re.split(r"[\r\n]+", output):
        line = line.strip()
        if not line:
            continue
        # 提取路径（最多分割2次，保留路径中的空格）
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

    # 初始化子仓库
    cmd_init = f"git submodule update --init {sm_quoted}"
    safe_print(f"[Submodule] Initializing: {submodule_rel_path}")
    success, _ = run_command(cmd_init, cwd=git_root)
    if not success:
        safe_print(f"[Error] Failed to initialize submodule: {submodule_rel_path}")
        return False

    # 暂存子仓库
    cmd_add = f"git add {sm_quoted}"
    safe_print(f"[Submodule] Staging: {submodule_rel_path}")
    success, _ = run_command(cmd_add, cwd=git_root)
    if not success:
        safe_print(f"[Error] Failed to stage submodule: {submodule_rel_path}")
        return False
    return True


def get_uncommitted_files():
    """获取未提交文件（强制按行分割路径，逐个验证）"""
    git_root = find_git_root()
    if not git_root:
        safe_print("[Error]: Could not find Git repository root")
        return [], [], []

    # 1. 获取子仓库路径
    submodule_abs_paths = get_git_submodule_paths(git_root)

    # 2. 获取普通文件修改（强制按换行符分割）
    cmd_modified = "git diff --name-only --diff-filter=ADM"
    success, modified_output = run_command(
        cmd_modified, cwd=git_root, capture_output=True
    )
    cmd_untracked = "git ls-files --others --exclude-standard"
    success_untracked, untracked_output = run_command(
        cmd_untracked, cwd=git_root, capture_output=True
    )

    # 关键修复：强制按换行符分割（无论\n还是\r\n），确保每个路径单独存在
    all_modified = [
        f.strip() for f in re.split(r"[\r\n]+", modified_output) if f.strip()
    ]
    all_untracked = [
        f.strip() for f in re.split(r"[\r\n]+", untracked_output) if f.strip()
    ]

    # 过滤子仓库文件
    filtered_modified = filter_out_submodules(
        all_modified, submodule_abs_paths, git_root
    )
    filtered_untracked = filter_out_submodules(
        all_untracked, submodule_abs_paths, git_root
    )

    # 3. 逐个验证文件有效性（修复批量验证错误）
    valid_normal = []
    invalid_normal = []
    # 逐个处理每个文件，而不是批量处理
    for file_list in [filtered_modified, filtered_untracked]:
        for f in file_list:
            # 跳过空路径
            if not f:
                continue
            f_abs = os.path.abspath(os.path.join(git_root, f))
            # 检查文件是否存在或被Git删除
            if os.path.exists(f_abs) or is_file_deleted_by_git(f, git_root):
                valid_normal.append(f)
            else:
                invalid_normal.append(f)

    # 4. 获取修改的子仓库
    modified_submodules = get_git_submodule_modified(git_root)

    # 打印调试信息
    safe_print(f"[Debug]: Found {len(valid_normal)} valid normal files")
    safe_print(f"[Debug]: Found {len(modified_submodules)} modified submodules")
    if invalid_normal:
        safe_print("[Warning]: Invalid file paths (not exist or encoding issue):")
        for f in invalid_normal:
            safe_print(f"  {f}")

    return valid_normal, invalid_normal, modified_submodules


def is_file_deleted_by_git(file_rel_path, git_root):
    """逐个判断文件是否被删除"""
    if not git_root or not file_rel_path:
        return False
    quoted_path = safe_quote_path(file_rel_path)
    cmd = f"git diff --name-only --diff-filter=D -- {quoted_path}"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    # 验证输出是否包含当前文件路径（处理可能的换行）
    deleted_files = [f.strip() for f in re.split(r"[\r\n]+", output) if f.strip()]
    return file_rel_path in deleted_files


def get_file_size(file_rel_path, git_root):
    """获取文件大小（逐个处理）"""
    if not git_root or not file_rel_path:
        return 0
    submodule_abs_paths = get_git_submodule_paths(git_root)
    file_abs = os.path.abspath(os.path.join(git_root, file_rel_path))
    for sm_abs in submodule_abs_paths:
        if os.path.commonprefix([file_abs, sm_abs]) == sm_abs:
            return 0  # 子仓库文件不计算大小

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

    # 1. 暂存普通文件
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

    # 2. 处理子仓库
    if modified_submodules:
        safe_print(f"[Info]: Handling {len(modified_submodules)} submodules...")
        for sm_rel in modified_submodules:
            if not handle_git_submodule(sm_rel, git_root):
                return False

    # 3. 提交
    commit_msg_abs = os.path.abspath(commit_msg_file)
    cmd_commit = f"git commit -F {safe_quote_path(commit_msg_abs)}"
    safe_print("[Info]: Committing changes...")
    success, _ = run_command(cmd_commit, cwd=git_root)
    if not success:
        safe_print("[Error]: Failed to commit changes")
        return False

    # 4. 推送
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

    # 初始化
    git_root = find_git_root()
    original_commit_file = os.path.abspath(sys.argv[1].replace("\r", ""))
    commit_msg_file = f"{original_commit_file}.tmp"
    push_allow = False

    # 1. 处理提交信息
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

    # 2. 获取可提交内容
    valid_normal, _, modified_submodules = get_uncommitted_files()
    # 过滤超大文件
    filtered_normal = []
    for f in valid_normal:
        file_size = get_file_size(f, git_root)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"[Warning]: File exceeds 100MB (skipped): '{f}' ({file_size/1024/1024:.2f}MB)"
            )
            continue
        filtered_normal.append(f)

    # 3. 检查是否有内容可提交
    total = len(filtered_normal) + len(modified_submodules)
    if total == 0:
        safe_print("[Info]: No valid content to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)
    safe_print(
        f"[Info]: To commit: {len(filtered_normal)} files + {len(modified_submodules)} submodules"
    )

    # 4. 提交并推送
    if not commit_and_push(filtered_normal, modified_submodules, commit_msg_file):
        safe_print("[Error]: Commit & Push failed")
        os.remove(commit_msg_file)
        sys.exit(1)

    # 5. 清理临时文件
    os.remove(commit_msg_file)
    safe_print("[Complete]: All content committed and pushed successfully!")


if __name__ == "__main__":
    main()
