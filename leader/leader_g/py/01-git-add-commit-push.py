import os
import sys
import time
import re
import subprocess
import random
import shutil
from pathlib import Path

MAX_BATCH_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 50 * 1024 * 1024
MAX_RETRIES = 5
CUR_WORKING_DIR = ""
SPLIT_FILE_EXTENSION = ".split_part_"


class FilteredStream:
    def __init__(self, original_stream):
        self.original_stream = original_stream

    def write(self, text):
        if text and text.strip():
            if not re.match(r"^[\x00-\x1F\x7F\x1b]*$", text):
                self.original_stream.write(text + "\n")
                self.original_stream.flush()

    def flush(self):
        self.original_stream.flush()


sys.stdout = FilteredStream(sys.stdout)
sys.stderr = FilteredStream(sys.stderr)


def safe_quote_path(path):
    if re.search(r'[\s，,()"]', path):
        return f'"{path.replace('"', '\\"')}"'
    return path


def get_git_env():
    env = os.environ.copy()
    env["GIT_COMMITTER_ENCODING"] = "utf-8"
    env["GIT_AUTHOR_ENCODING"] = "utf-8"
    env["LANG"] = "zh_CN.UTF-8"
    env["PYTHONIOENCODING"] = "utf-8"
    env["LC_ALL"] = "zh_CN.UTF-8"
    env["TERM"] = "dumb"
    env["GIT_CONFIG_NOSYSTEM"] = "1"
    env["GIT_PAGER"] = "cat"
    env["PAGER"] = "cat"
    env["ANSICON"] = "0"
    env["ConEmuANSI"] = "OFF"
    env["ENABLE_VIRTUAL_TERMINAL_PROCESSING"] = "0"
    return env


def run_command(cmd, cwd=None, capture_output=False):
    global CUR_WORKING_DIR
    original_cwd = os.getcwd()
    output = ""
    try:
        if cwd:
            os.chdir(cwd)
            if CUR_WORKING_DIR != cwd:
                CUR_WORKING_DIR = cwd
                print(f"[Working directory]: {cwd}")
        print(f"[Executing command]: {cmd}")
        env = get_git_env()
        if capture_output:
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
                    print(line.rstrip())
                    output_lines.append(line)
            output = "\n".join(output_lines)
            return process.returncode == 0, output
        else:
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
                    print(line.rstrip())
            return process.returncode == 0, ""
    except Exception as e:
        print(f"[Error] Command failed: {str(e)}")
        return False, str(e)
    finally:
        if cwd:
            os.chdir(original_cwd)


def get_git_submodule_paths(git_root):
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
    if not git_root or not submodule_rel_path:
        return False
    sm_abs = os.path.abspath(os.path.join(git_root, submodule_rel_path))
    sm_quoted = safe_quote_path(sm_abs)
    cmd_init = f"git submodule update --init {sm_quoted}"
    print(f"[Submodule] Initializing: {submodule_rel_path}")
    success, _ = run_command(cmd_init, cwd=git_root)
    if not success:
        print(f"[Error] Failed to initialize submodule: {submodule_rel_path}")
        return False
    cmd_add = f"git add {sm_quoted}"
    print(f"[Submodule] Staging: {submodule_rel_path}")
    success, _ = run_command(cmd_add, cwd=git_root)
    if not success:
        print(f"[Error] Failed to stage submodule: {submodule_rel_path}")
        return False
    return True


def get_uncommitted_files():
    git_root = find_git_root()
    if not git_root:
        print("[Error]: Could not find Git repository root")
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
    print(f"[Debug]: Found {len(valid_normal)} valid normal files")
    print(f"[Debug]: Found {len(modified_submodules)} modified submodules")
    if invalid_normal:
        print("[Warning]: Invalid file paths (not exist or encoding issue):")
        for f in invalid_normal:
            print(f"  {f}")
    return valid_normal, invalid_normal, modified_submodules


def is_file_deleted_by_git(file_rel_path, git_root):
    if not git_root or not file_rel_path:
        return False
    quoted_path = safe_quote_path(file_rel_path)
    cmd = f"git diff --name-only --diff-filter=D -- {quoted_path}"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    deleted_files = [f.strip() for f in re.split(r"[\r\n]+", output) if f.strip()]
    return file_rel_path in deleted_files


def get_file_size(file_rel_path, git_root):
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
            print(f"[Warning]: File not found: {file_rel_path}")
            return 0
        return os.path.getsize(file_abs)
    except OSError as e:
        print(f"[Warning]: Failed to get size of '{file_rel_path}' - {str(e)}")
        return 0


def find_git_root(start_path=None):
    current_path = start_path or os.getcwd()
    while True:
        git_dir = os.path.join(current_path, ".git")
        if os.path.exists(git_dir) and os.path.isdir(git_dir):
            return current_path
        parent_path = os.path.dirname(current_path)
        if parent_path == current_path:
            return None
        current_path = parent_path


def split_large_file(file_path, git_root):
    """
    分割大文件为多个小文件
    返回分割后的文件列表
    """
    try:
        abs_file_path = os.path.join(git_root, file_path)
        file_size = os.path.getsize(abs_file_path)

        # 随机选择分割大小（30-50MB）
        chunk_size = random.randint(30, 50) * 1024 * 1024

        # 计算需要分割的块数
        num_chunks = (file_size + chunk_size - 1) // chunk_size

        print(
            f"[Split] Splitting {file_path} ({file_size/1024/1024:.2f}MB) into {num_chunks} chunks"
        )

        split_files = []
        with open(abs_file_path, "rb") as f:
            for i in range(num_chunks):
                chunk_file_path = f"{abs_file_path}{SPLIT_FILE_EXTENSION}{i+1:03d}"
                relative_chunk_path = f"{file_path}{SPLIT_FILE_EXTENSION}{i+1:03d}"

                with open(chunk_file_path, "wb") as chunk_file:
                    # 读取chunk_size大小的数据
                    data = f.read(chunk_size)
                    chunk_file.write(data)

                split_files.append(relative_chunk_path)
                print(
                    f"[Split] Created chunk: {relative_chunk_path} ({len(data)/1024/1024:.2f}MB)"
                )

        # 将原文件添加到.gitignore
        add_to_gitignore(file_path, git_root)

        return split_files

    except Exception as e:
        print(f"[Error] Failed to split file {file_path}: {str(e)}")
        return []


def add_to_gitignore(file_pattern, git_root):
    """
    将文件模式添加到.gitignore
    """
    gitignore_path = os.path.join(git_root, ".gitignore")

    try:
        # 读取现有的.gitignore内容
        existing_patterns = set()
        if os.path.exists(gitignore_path):
            with open(gitignore_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        existing_patterns.add(line)

        # 如果模式不存在，则添加
        if file_pattern not in existing_patterns:
            with open(gitignore_path, "a", encoding="utf-8") as f:
                f.write(f"\n{file_pattern}\n")
            print(f"[GitIgnore] Added {file_pattern} to .gitignore")

            # 暂存.gitignore文件
            quoted_gitignore = safe_quote_path(gitignore_path)
            cmd_add = f"git add {quoted_gitignore}"
            success, _ = run_command(cmd_add, cwd=git_root)
            if not success:
                print(f"[Warning] Failed to stage .gitignore file")

    except Exception as e:
        print(f"[Error] Failed to update .gitignore: {str(e)}")


def commit_and_push(valid_normal, modified_submodules, commit_msg_file):
    git_root = find_git_root()
    if not git_root:
        print("[Error]: Could not find Git repository root")
        return False
    if valid_normal:
        print(f"[Info]: Staging {len(valid_normal)} normal files...")
        files_quoted = [
            safe_quote_path(os.path.join(git_root, f)) for f in valid_normal
        ]
        cmd_add = f"git add {' '.join(files_quoted)}"
        success, _ = run_command(cmd_add, cwd=git_root)
        if not success:
            print("[Error]: Failed to stage normal files")
            return False
    if modified_submodules:
        print(f"[Info]: Handling {len(modified_submodules)} submodules...")
        for sm_rel in modified_submodules:
            if not handle_git_submodule(sm_rel, git_root):
                return False
    commit_msg_abs = os.path.abspath(commit_msg_file)
    cmd_commit = f"git commit -F {safe_quote_path(commit_msg_abs)}"
    print("[Info]: Committing changes...")
    success, _ = run_command(cmd_commit, cwd=git_root)
    if not success:
        print("[Error]: Failed to commit changes")
        return False
    total = len(valid_normal) + len(modified_submodules)
    print(f"[Success]: Committed {total} items (files + submodules)")
    for retry in range(MAX_RETRIES):
        print(f"[Pushing]: Attempt {retry+1}/{MAX_RETRIES}...")
        cmd_push = "git push --recurse-submodules=on-demand"
        success, _ = run_command(cmd_push, cwd=git_root)
        if success:
            print("[Success]: Push completed successfully")
            return True
        print(f"[Error]: Push attempt {retry+1} failed")
        if retry < MAX_RETRIES - 1:
            time.sleep(2)
    print(f"[Error]: Maximum retries ({MAX_RETRIES}) reached")
    return False


def process_commit_file(original_commit_file):
    commit_msg_file = f"{original_commit_file}.tmp"
    push_allow = False
    if not os.path.exists(original_commit_file):
        print(f"[Error]: Commit file not found: '{original_commit_file}'")
        sys.exit(1)
    try:
        with open(original_commit_file, "r", encoding="utf-8", errors="replace") as f:
            lines = [line.replace("\r", "") for line in f.readlines()]
        with open(commit_msg_file, "w", encoding="utf-8") as f:
            for line in lines:
                if line.strip().startswith("#") or not line.strip():
                    continue
                f.write(f"{line.strip()}\n")
                push_allow = True
    except Exception as e:
        print(f"[Error]: Process commit file failed - {str(e)}")
        if os.path.exists(commit_msg_file):
            os.remove(commit_msg_file)
        sys.exit(1)
    if not push_allow:
        print("[Error]: Commit message is empty (filtered comments/blank lines)")
        os.remove(commit_msg_file)
        sys.exit(1)
    return commit_msg_file


def main():
    if len(sys.argv) < 2:
        print("[Error]: Usage: python git_batch_commit.py <commit_message_file.txt>")
        sys.exit(1)
    git_root = find_git_root()
    original_commit_file = os.path.abspath(sys.argv[1].replace("\r", ""))
    commit_msg_file = process_commit_file(original_commit_file)
    valid_normal, _, modified_submodules = get_uncommitted_files()

    # 处理大文件分割
    filtered_normal = []
    split_files = []

    for f in valid_normal:
        file_size = get_file_size(f, git_root)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(f"[Info]: Large file detected: {f} ({file_size/1024/1024:.2f}MB)")
            # 分割大文件
            chunks = split_large_file(f, git_root)
            if chunks:
                split_files.extend(chunks)
                print(f"[Info]: Split {f} into {len(chunks)} chunks")
            else:
                print(f"[Warning]: Failed to split large file: {f}")
        else:
            filtered_normal.append(f)

    # 将分割后的文件加入提交列表
    filtered_normal.extend(split_files)

    total = len(filtered_normal) + len(modified_submodules)
    if total == 0:
        print("[Info]: No valid content to commit. Exiting.")
        os.remove(commit_msg_file)
        sys.exit(0)

    print(
        f"[Info]: To commit: {len(filtered_normal)} files + {len(modified_submodules)} submodules"
    )
    if split_files:
        print(f"[Info]: Including {len(split_files)} split file chunks")

    result = commit_and_push(filtered_normal, modified_submodules, commit_msg_file)
    if os.path.exists(commit_msg_file):
        os.remove(commit_msg_file)
    if result:
        print("[Complete]: All content committed and pushed successfully!")
    else:
        print("[Error]: Commit & Push failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
