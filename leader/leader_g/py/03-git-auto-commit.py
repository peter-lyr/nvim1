import os
import sys
import subprocess
import math
import time


def run_git_command(cmd, max_retries=3):
    print(f"执行命令: {cmd}")
    result = 0
    for attempt in range(max_retries):
        result = os.system(cmd)
        if result == 0:
            return result
        else:
            print(f"命令执行失败 (尝试 {attempt+1}/{max_retries}): {cmd}")
            if attempt < max_retries - 1:
                wait_time = 5 * (attempt + 1)
                print(f"等待 {wait_time} 秒后重试...")
                time.sleep(wait_time)
    return result


def check_network_connection():
    try:
        result = subprocess.run(
            ["ping", "-n", "1", "github.com"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            timeout=10,
        )
        return result.returncode == 0
    except:
        return False


def get_git_root():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        print("错误: 当前目录不是git仓库")
        return None


def get_unstaged_files():
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain", "-uall"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            check=True,
        )
        if result.stdout is None:
            return []
        files = []
        for line in result.stdout.strip().split("\n"):
            if line:
                filename = line[3:].strip()
                files.append(filename)
        return files
    except subprocess.CalledProcessError:
        return []


def is_file_already_split(file_path):
    file_dir = os.path.dirname(file_path)
    file_name = os.path.basename(file_path)
    split_marker = os.path.join(file_dir, f".{file_name}.split")
    return os.path.exists(split_marker)


def mark_file_as_split(file_path):
    file_dir = os.path.dirname(file_path)
    file_name = os.path.basename(file_path)
    split_marker = os.path.join(file_dir, f".{file_name}.split")
    with open(split_marker, "wb") as f:
        f.write(b"")


def add_to_gitignore(file_path):
    file_name = os.path.basename(file_path)
    file_base, file_ext = os.path.splitext(file_name)
    original_file = file_name
    merged_file = f"{file_base}-merged{file_ext}"
    gitignore_path = os.path.join(os.path.dirname(file_path), ".gitignore")
    existing_lines = set()
    if os.path.exists(gitignore_path):
        with open(gitignore_path, "r", encoding="utf-8") as f:
            existing_lines = set(line.strip() for line in f.readlines())
    lines_to_add = []
    if original_file not in existing_lines:
        lines_to_add.append(original_file)
    if merged_file not in existing_lines:
        lines_to_add.append(merged_file)
    if lines_to_add:
        with open(gitignore_path, "a", encoding="utf-8") as f:
            for line in lines_to_add:
                f.write(f"{line}\n")
                print(f"已将 {line} 添加到 {gitignore_path}")


def split_large_file(file_path, chunk_size=50 * 1024 * 1024):
    print(f"开始拆分大文件: {file_path}")
    file_dir = os.path.dirname(file_path)
    file_name = os.path.basename(file_path)
    file_base, file_ext = os.path.splitext(file_name)
    file_size = os.path.getsize(file_path)
    num_chunks = math.ceil(file_size / chunk_size)
    chunk_files = []
    with open(file_path, "rb") as original_file:
        for i in range(num_chunks):
            chunk_file_name = f"{file_base}_part{i+1:03d}{file_ext}"
            chunk_file_path = os.path.join(file_dir, chunk_file_name)
            with open(chunk_file_path, "wb") as chunk_file:
                data = original_file.read(chunk_size)
                chunk_file.write(data)
            chunk_files.append(chunk_file_path)
            print(f"创建分块文件: {chunk_file_path} ({len(data)} bytes)")
    mark_file_as_split(file_path)
    return chunk_files


def process_large_files(git_root):
    large_files = []
    chunk_files = []
    unstaged_files = get_unstaged_files()
    for file in unstaged_files:
        file_path = os.path.join(git_root, file)
        if os.path.isfile(file_path):
            file_size = os.path.getsize(file_path)
            if file_size > 50 * 1024 * 1024:
                if not is_file_already_split(file_path):
                    large_files.append(file_path)
                else:
                    print(f"文件 {file} 已经被拆分过，跳过")
    for file_path in large_files:
        chunks = split_large_file(file_path)
        chunk_files.extend(chunks)
        add_to_gitignore(file_path)
    return chunk_files


def get_file_size(file_path):
    return os.path.getsize(file_path) if os.path.isfile(file_path) else 0


def check_remote_connection():
    print("检查远程仓库连接...")
    try:
        result = subprocess.run(
            ["git", "config", "--get", "remote.origin.url"],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if result.returncode != 0:
            print("错误: 未配置远程仓库 origin")
            return False
    except subprocess.TimeoutExpired:
        print("git config 命令超时")
        return False
    for i in range(2):
        if check_network_connection():
            print("远程仓库连接正常")
            return True
        print(f"网络连接检查失败，等待 3 秒后重试... ({i+1}/2)")
        time.sleep(3)
    print("警告: 网络连接可能有问题，但仍将继续尝试提交")
    return True


def batch_commit_files(commit_msg_file, git_root):
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain", "-uall"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            check=True,
        )
        all_files = []
        if result.stdout is None:
            return False
        for line in result.stdout.strip().split("\n"):
            if line:
                parts = line.split(maxsplit=1)
                if len(parts) >= 2:
                    status = parts[0]
                    filename = parts[1].strip()
                    file_path = os.path.join(git_root, filename)
                    if status in (
                        "??",
                        "?",
                        "M",
                        "A",
                        " M",
                        "M ",
                        "A ",
                        "AM",
                        "MM",
                    ) and os.path.isfile(file_path):
                        all_files.append((filename, get_file_size(file_path)))
                else:
                    print(f"无法解析的git状态行: {line}")
        batches = []
        current_batch = []
        current_batch_size = 0
        max_batch_size = 100 * 1024 * 1024
        for filename, size in all_files:
            if size > max_batch_size:
                print(
                    f"警告: 文件 {filename} 大小 {size/(1024*1024):.2f}M 超过单次提交限制"
                )
                continue
            if not current_batch:
                current_batch.append(filename)
                current_batch_size = size
            elif current_batch_size + size <= max_batch_size:
                current_batch.append(filename)
                current_batch_size += size
            else:
                batches.append((current_batch, current_batch_size))
                current_batch = [filename]
                current_batch_size = size
        if current_batch:
            batches.append((current_batch, current_batch_size))
        if not check_remote_connection():
            print("无法连接到远程仓库，请检查网络连接")
            return False
        for i, (batch, batch_size) in enumerate(batches):
            print(
                f"\n提交批次 {i+1}/{len(batches)}，包含 {len(batch)} 个文件，总大小 {batch_size/(1024*1024):.2f}M"
            )
            for file in batch:
                run_git_command(
                    f'git add "{file}" # {os.path.getsize(file)/(1024*1024):.2f}M'
                )
            commit_result = run_git_command(f'git commit -F "{commit_msg_file}"')
            if commit_result != 0:
                print(f"提交批次 {i+1} 失败")
                return False
            push_result = run_git_command("git push", max_retries=5)
            if push_result != 0:
                print(f"推送批次 {i+1} 失败")
                return False
            print(f"批次 {i+1} 提交并推送成功")
        return True
    except subprocess.CalledProcessError as e:
        print(f"获取git状态失败: {e}")
        return False


def main():
    if len(sys.argv) != 2:
        print("用法: python git_auto_commit.py <commit_message_file>")
        sys.exit(1)
    commit_msg_file = sys.argv[1]
    if not os.path.exists(commit_msg_file):
        print(f"错误: 提交信息文件不存在: {commit_msg_file}")
        sys.exit(1)
    git_root = get_git_root()
    if not git_root:
        sys.exit(1)
    print(f"Git仓库根目录: {git_root}")
    os.chdir(git_root)
    print("检查大文件...")
    chunk_files = process_large_files(git_root)
    if chunk_files:
        print(f"拆分了 {len(chunk_files)} 个大文件")
    print("开始分批提交...")
    success = batch_commit_files(commit_msg_file, git_root)
    if success:
        print("\n所有操作完成!")
    else:
        print("\n操作过程中出现错误!")
        sys.exit(1)


if __name__ == "__main__":
    main()
