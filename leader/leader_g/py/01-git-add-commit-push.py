import os
import sys
import time
import re
import subprocess
import random

MAX_BATCH_SIZE = 100 * 1024 * 1024  # 100MB 每批次
MAX_SINGLE_FILE_SIZE = 50 * 1024 * 1024  # 50MB 单个文件限制
MAX_RETRIES = 5
CUR_WORKING_DIR = ""
SPLIT_FILE_EXTENSION = ".split_part_"
MAX_CMD_LENGTH = 8000

_git_submodule_cache = None
_git_deleted_files_cache = None


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


def run_command(cmd, cwd=None, capture_output=False, real_time_output=True):
    """修改后的 run_command 函数，支持真正的实时输出"""
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
        if capture_output and not real_time_output:
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
            output_lines = []
            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    print(line.rstrip())
                    sys.stdout.flush()
                    if capture_output:
                        output_lines.append(line)
            if capture_output:
                output = "\n".join(output_lines)
            return process.returncode == 0, output
    except Exception as e:
        print(f"[Error] Command failed: {str(e)}")
        return False, str(e)
    finally:
        if cwd:
            os.chdir(original_cwd)


def run_git_push(cwd=None):
    """专门用于运行 git push 命令，使用 os.system 确保实时输出"""
    original_cwd = os.getcwd()
    try:
        if cwd:
            os.chdir(cwd)

        cmd = "git push --recurse-submodules=on-demand"
        print(f"[Executing command]: {cmd}")

        # 使用 os.system 来确保实时输出
        returncode = os.system(cmd)
        success = returncode == 0

        return success, ""
    except Exception as e:
        print(f"[Error] git push failed: {str(e)}")
        return False, str(e)
    finally:
        if cwd:
            os.chdir(original_cwd)


def get_git_submodule_paths(git_root):
    global _git_submodule_cache
    if _git_submodule_cache is not None:
        return _git_submodule_cache
    if not git_root:
        return []
    cmd = "git submodule status --recursive"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success or not output:
        _git_submodule_cache = []
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
    _git_submodule_cache = submodule_abs_paths
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


def get_deleted_files(git_root):
    """一次性获取所有被删除的文件"""
    global _git_deleted_files_cache
    if _git_deleted_files_cache is not None:
        return _git_deleted_files_cache
    cmd = "git diff --name-only --diff-filter=D"
    success, output = run_command(cmd, cwd=git_root, capture_output=True)
    if not success:
        _git_deleted_files_cache = set()
        return set()
    deleted_files = {f.strip() for f in re.split(r"[\r\n]+", output) if f.strip()}
    _git_deleted_files_cache = deleted_files
    return deleted_files


def get_uncommitted_files():
    global _git_submodule_cache, _git_deleted_files_cache
    _git_submodule_cache = None
    _git_deleted_files_cache = None
    git_root = find_git_root()
    if not git_root:
        print("[Error]: Could not find Git repository root")
        return [], [], []
    submodule_abs_paths = get_git_submodule_paths(git_root)
    deleted_files = get_deleted_files(git_root)
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
            if os.path.exists(f_abs) or f in deleted_files:
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
    """使用缓存的删除文件列表"""
    deleted_files = get_deleted_files(git_root)
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
        deleted_files = get_deleted_files(git_root)
        if file_rel_path in deleted_files:
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
    分割大文件为多个小文件，每个文件大小随机且不同
    返回分割后的文件列表
    """
    try:
        abs_file_path = os.path.join(git_root, file_path)
        file_size = os.path.getsize(abs_file_path)
        file_dir = os.path.dirname(abs_file_path)
        avg_chunk_size = 40 * 1024 * 1024
        num_chunks = max(2, (file_size + avg_chunk_size - 1) // avg_chunk_size)
        print(
            f"[Split] Splitting {file_path} ({file_size/1024/1024:.2f}MB) into {num_chunks} chunks"
        )
        chunk_sizes = []
        remaining_size = file_size
        min_chunk = 30 * 1024 * 1024
        max_chunk = 50 * 1024 * 1024
        for i in range(num_chunks - 1):
            if remaining_size <= min_chunk:
                chunk_size = remaining_size
            else:
                available_max = min(
                    max_chunk, remaining_size - (num_chunks - i - 1) * min_chunk
                )
                available_min = max(
                    min_chunk, remaining_size - (num_chunks - i - 1) * max_chunk
                )
                if available_min >= available_max:
                    chunk_size = available_min
                else:
                    chunk_size = random.randint(available_min, available_max)
            chunk_sizes.append(chunk_size)
            remaining_size -= chunk_size
        chunk_sizes.append(remaining_size)
        split_files = []
        with open(abs_file_path, "rb") as f:
            for i, chunk_size in enumerate(chunk_sizes):
                chunk_file_path = f"{abs_file_path}{SPLIT_FILE_EXTENSION}{i+1:03d}"
                relative_chunk_path = f"{file_path}{SPLIT_FILE_EXTENSION}{i+1:03d}"
                with open(chunk_file_path, "wb") as chunk_file:
                    data = f.read(chunk_size)
                    chunk_file.write(data)
                split_files.append(relative_chunk_path)
                print(
                    f"[Split] Created chunk: {relative_chunk_path} ({len(data)/1024/1024:.2f}MB)"
                )
        add_to_local_gitignore(file_path, file_dir, git_root)
        return split_files
    except Exception as e:
        print(f"[Error] Failed to split file {file_path}: {str(e)}")
        return []


def add_to_local_gitignore(file_pattern, local_dir, git_root):
    """
    在文件同目录下创建.gitignore文件
    """
    try:
        gitignore_path = os.path.join(local_dir, ".gitignore")
        if os.path.commonpath([local_dir, git_root]) == git_root:
            relative_dir = os.path.relpath(local_dir, git_root)
            if relative_dir == ".":
                ignore_pattern = file_pattern
            else:
                ignore_pattern = os.path.join(relative_dir, file_pattern)
        else:
            ignore_pattern = file_pattern
        existing_patterns = set()
        if os.path.exists(gitignore_path):
            with open(gitignore_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        existing_patterns.add(line)
        if ignore_pattern not in existing_patterns:
            with open(gitignore_path, "a", encoding="utf-8") as f:
                f.write(f"\n{ignore_pattern}\n")
            print(f"[GitIgnore] Added {ignore_pattern} to {gitignore_path}")
        merged_pattern = f"{ignore_pattern}.merged"
        if merged_pattern not in existing_patterns:
            with open(gitignore_path, "a", encoding="utf-8") as f:
                f.write(f"{merged_pattern}\n")
            print(f"[GitIgnore] Added {merged_pattern} to {gitignore_path}")
        quoted_gitignore = safe_quote_path(gitignore_path)
        cmd_add = f"git add {quoted_gitignore}"
        success, _ = run_command(cmd_add, cwd=git_root)
        if not success:
            print(f"[Warning] Failed to stage .gitignore file")
    except Exception as e:
        print(f"[Error] Failed to update local .gitignore: {str(e)}")


def batch_add_files(files, git_root):
    """分批添加文件，避免命令行过长"""
    if not files:
        return True
    print(f"[Info]: Staging {len(files)} files in batches...")
    current_batch = []
    current_length = 0

    for i, f in enumerate(files):
        file_path = safe_quote_path(os.path.join(git_root, f))
        file_length = len(file_path) + 1

        if current_batch and (
            current_length + file_length > MAX_CMD_LENGTH or i == len(files) - 1
        ):
            cmd_add = f"git add {' '.join(current_batch)}"
            success, _ = run_command(cmd_add, cwd=git_root)
            if not success:
                print(f"[Error]: Failed to stage batch of {len(current_batch)} files")
                return False
            print(f"[Info]: Successfully staged batch of {len(current_batch)} files")
            current_batch = []
            current_length = 0

        current_batch.append(file_path)
        current_length += file_length

    if current_batch:
        cmd_add = f"git add {' '.join(current_batch)}"
        success, _ = run_command(cmd_add, cwd=git_root)
        if not success:
            print(f"[Error]: Failed to stage final batch of {len(current_batch)} files")
            return False
        print(f"[Info]: Successfully staged final batch of {len(current_batch)} files")

    return True


def calculate_batches(files, git_root):
    """根据文件总大小计算需要分成多少个批次"""
    if not files:
        return []

    total_size = 0
    for f in files:
        total_size += get_file_size(f, git_root)

    print(f"[Batch] Total files size: {total_size/1024/1024:.2f}MB")
    print(f"[Batch] Max batch size: {MAX_BATCH_SIZE/1024/1024:.2f}MB")

    if total_size <= MAX_BATCH_SIZE:
        print("[Batch] All files fit in one batch")
        return [files]

    num_batches = (total_size + MAX_BATCH_SIZE - 1) // MAX_BATCH_SIZE
    print(f"[Batch] Need to split into {num_batches} batches")

    # 按文件大小降序排序，优先处理大文件
    files_with_size = [(f, get_file_size(f, git_root)) for f in files]
    files_with_size.sort(key=lambda x: x[1], reverse=True)

    batches = [[] for _ in range(num_batches)]
    batch_sizes = [0] * num_batches

    # 使用贪心算法分配文件到各个批次
    for file_path, file_size in files_with_size:
        # 找到当前最小的批次
        min_batch_index = batch_sizes.index(min(batch_sizes))
        batches[min_batch_index].append(file_path)
        batch_sizes[min_batch_index] += file_size

    # 打印批次信息
    for i, (batch, size) in enumerate(zip(batches, batch_sizes)):
        print(f"[Batch {i+1}]: {len(batch)} files, {size/1024/1024:.2f}MB")

    return batches


def commit_batch(
    files, modified_submodules, commit_msg_file, batch_num=1, total_batches=1
):
    """提交单个批次"""
    git_root = find_git_root()
    if not git_root:
        print("[Error]: Could not find Git repository root")
        return False

    # 添加文件
    if files:
        if not batch_add_files(files, git_root):
            print("[Error]: Failed to stage normal files")
            return False

    # 处理子模块（只在第一批次处理）
    if batch_num == 1 and modified_submodules:
        print(f"[Info]: Handling {len(modified_submodules)} submodules...")
        for sm_rel in modified_submodules:
            if not handle_git_submodule(sm_rel, git_root):
                return False

    # 生成批次提交信息
    commit_msg_abs = os.path.abspath(commit_msg_file)
    if total_batches > 1:
        batch_commit_msg = f"{commit_msg_file}.batch{batch_num}"
        try:
            with open(commit_msg_abs, "r", encoding="utf-8") as f:
                original_msg = f.read().strip()
            batch_msg = f"{original_msg}\n\n[Batch {batch_num}/{total_batches}]"
            with open(batch_commit_msg, "w", encoding="utf-8") as f:
                f.write(batch_msg)
            commit_msg_abs = batch_commit_msg
        except Exception as e:
            print(f"[Warning]: Failed to create batch commit message: {str(e)}")

    # 提交
    cmd_commit = f"git commit -F {safe_quote_path(commit_msg_abs)}"
    print(f"[Info]: Committing batch {batch_num}/{total_batches}...")
    success, _ = run_command(cmd_commit, cwd=git_root, capture_output=False)
    if not success:
        print(f"[Error]: Failed to commit batch {batch_num}")
        return False

    # 推送 - 使用专门的 git push 函数
    for retry in range(MAX_RETRIES):
        print(f"[Pushing batch {batch_num}]: Attempt {retry+1}/{MAX_RETRIES}...")
        success, _ = run_git_push(cwd=git_root)
        if success:
            print(f"[Success]: Batch {batch_num} push completed successfully")

            # 清理临时提交信息文件
            if (
                total_batches > 1
                and os.path.exists(commit_msg_abs)
                and commit_msg_abs != os.path.abspath(commit_msg_file)
            ):
                os.remove(commit_msg_abs)
            return True

        print(f"[Error]: Batch {batch_num} push attempt {retry+1} failed")
        if retry < MAX_RETRIES - 1:
            time.sleep(2)

    print(f"[Error]: Batch {batch_num} maximum retries ({MAX_RETRIES}) reached")
    return False


def process_commit_file(original_commit_file):
    commit_msg_file = f"{original_commit_file}.tmpcommit"
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
    filtered_normal = []
    split_files = []
    for f in valid_normal:
        file_size = get_file_size(f, git_root)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(f"[Info]: Large file detected: {f} ({file_size/1024/1024:.2f}MB)")
            chunks = split_large_file(f, git_root)
            if chunks:
                split_files.extend(chunks)
                print(f"[Info]: Split {f} into {len(chunks)} chunks")
            else:
                print(f"[Warning]: Failed to split large file: {f}")
        else:
            filtered_normal.append(f)
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
    # 计算批次
    batches = calculate_batches(filtered_normal, git_root)
    if not batches:
        print("[Error]: Failed to calculate batches")
        os.remove(commit_msg_file)
        sys.exit(1)
    # 分批提交
    all_success = True
    for i, batch_files in enumerate(batches):
        batch_num = i + 1
        total_batches = len(batches)
        print(f"\n[Batch {batch_num}/{total_batches}] Starting...")
        success = commit_batch(
            batch_files, modified_submodules, commit_msg_file, batch_num, total_batches
        )
        if not success:
            print(f"[Error]: Batch {batch_num} failed")
            all_success = False
            break
        print(f"[Batch {batch_num}/{total_batches}] Completed successfully")
    # 清理
    if os.path.exists(commit_msg_file):
        os.remove(commit_msg_file)
    if all_success:
        print("[Complete]: All batches committed and pushed successfully!")
    else:
        print("[Error]: Some batches failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
