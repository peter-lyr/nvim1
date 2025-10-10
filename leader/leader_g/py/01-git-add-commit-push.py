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

# 定义控制字符常量
ESC = "\x1b"  # ^[ 字符
BEL = "\x07"  # ^G 字符
CTRL_CHARS = re.compile(r"[\x00-\x1F\x7F]")  # 所有ASCII控制字符

# 扩展目标序列，包含所有观察到的控制序列
TARGET_SEQUENCES = [
    r"\x1B\[\?9001l",
    r"\x1B\[\?1004l",
    r"\x1B\[\?9001h",
    r"\x1B\[\?1004h",
    r"\x1B\[\?25l",  # 隐藏光标
    r"\x1B\[\?25h",  # 显示光标
    r"\x1B\[2J",  # 清屏
    r"\x1B\[H",  # 光标归位
    r"\x1B\[m",  # 重置属性
    r"\x1B\]0;[^\x07]*\x07",  # 窗口标题序列
    r"\x1B\[[\d;]*m",  # SGR格式控制
]
TARGET_REGEX = re.compile("|".join(TARGET_SEQUENCES))

# 新增：更全面的控制序列正则表达式
CONTROL_SEQUENCES = re.compile(
    r"\x1B\[[\?]?[\d;]*[a-zA-Z]|"  # CSI序列
    r"\x1B\][^\x07]*\x07|"  # OSC序列（窗口标题等）
    r"\x1B[\(\)][\x20-\x2F]*[\x40-\x7E]|"  # 双字符序列
    r"[\x00-\x1F\x7F-\x9F]"  # 所有控制字符
)


def strip_control_chars(text):
    """终极控制字符过滤函数，针对所有观察到的控制序列"""
    if not isinstance(text, str):
        return text

    # 方法1：使用全面的控制序列正则表达式一次性清除
    cleaned = CONTROL_SEQUENCES.sub("", text)

    # 方法2：针对特定顽固序列再次清理
    cleaned = TARGET_REGEX.sub("", cleaned)

    # 方法3：移除所有ASCII控制字符（兜底）
    cleaned = CTRL_CHARS.sub("", cleaned)

    # 清理空白和格式
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    cleaned = re.sub(r" +", " ", cleaned)  # 合并多个空格

    return cleaned


def deep_clean(text):
    """深度清理函数，连续多次过滤确保彻底清除"""
    if not isinstance(text, str):
        text = str(text)

    cleaned = text
    # 连续多次过滤，确保最顽固序列被清除
    for _ in range(3):
        cleaned = strip_control_chars(cleaned)
        # 如果已经清理干净，提前退出
        if not re.search(r"[\x00-\x1F\x7F]", cleaned):
            break

    return cleaned


def safe_quote_path(path):
    """安全引用路径（处理空格、中文逗号等）"""
    if re.search(r'[\s，,()"]', path):
        return f'"{path.replace('"', '\\"')}"'
    return path


def safe_print(text):
    """安全打印函数，确保所有输出经过深度清理"""
    try:
        cleaned_text = deep_clean(text)
        if cleaned_text.strip():
            print(cleaned_text, flush=True)
    except Exception as e:
        error_text = f"[Error in safe_print]: {str(e)}"
        cleaned_error = deep_clean(error_text)
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
    """执行命令并对输出进行深度过滤"""
    original_cwd = os.getcwd()
    output = ""
    try:
        if cwd:
            os.chdir(cwd)
            safe_print(f"[Working directory]: {cwd}")

        # 过滤命令中的控制字符后再打印
        safe_print(f"[Executing command]: {deep_clean(cmd)}")
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
            # 读取时进行深度过滤
            with open(
                temp_file, "r", encoding="utf-8", errors="replace", newline=""
            ) as f:
                content = f.read()
                output = deep_clean(content)
            os.remove(temp_file)
        else:
            # 使用subprocess，修复bufsize警告
            process = subprocess.Popen(
                full_cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=cwd,
                env=env,
                bufsize=0,  # 无缓冲，解决二进制模式下行缓冲警告
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
                # 深度过滤
                cleaned_line = deep_clean(line_str)
                if cleaned_line.strip():
                    print(cleaned_line, flush=True)

            process.wait()
            if process.returncode != 0:
                return False, f"Command failed with exit code {process.returncode}"

        return True, output
    except Exception as e:
        err_msg = deep_clean(str(e))
        safe_print(f"[Error] Command failed: {err_msg}")
        return False, err_msg
    finally:
        if cwd:
            os.chdir(original_cwd)


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
        line = deep_clean(line).strip()
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
        line = deep_clean(line).strip()
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
        err_msg = deep_clean(str(e))
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
    clean_args = [deep_clean(arg) for arg in sys.argv]
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
            lines = [deep_clean(line).replace("\r", "") for line in f.readlines()]
        with open(commit_msg_file, "w", encoding="utf-8") as f:
            for line in lines:
                if line.strip().startswith("#") or not line.strip():
                    continue
                f.write(f"{line.strip()}\n")
                push_allow = True
    except Exception as e:
        safe_print(f"[Error]: Process commit file failed - {deep_clean(str(e))}")
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

    # 最终输出前的额外清理步骤
    if result:
        final_msg = "[Complete]: All content committed and pushed successfully!"
        # 对最终消息进行额外过滤
        final_msg = deep_clean(final_msg)
        print(final_msg, flush=True)
    else:
        final_msg = "[Error]: Commit & Push failed"
        print(deep_clean(final_msg), flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
