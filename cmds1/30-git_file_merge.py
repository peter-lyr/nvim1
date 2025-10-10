"""
文件合并工具
用法: python git_file_merge.py <任意分割文件>
"""

import os
import sys
import re
from pathlib import Path

SPLIT_FILE_EXTENSION = ".split_part_"


def find_split_files(any_split_file):
    """
    根据任意一个分割文件找到所有相关的分割文件
    """
    try:
        file_path = Path(any_split_file)
        if not file_path.exists():
            print(f"[Error]: File not found: {any_split_file}")
            return None, None

        # 提取基础文件名（去掉分割后缀和编号）
        filename = file_path.name
        pattern = re.escape(SPLIT_FILE_EXTENSION) + r"\d{3}$"
        match = re.search(pattern, filename)

        if not match:
            print(f"[Error]: Not a valid split file: {any_split_file}")
            return None, None

        base_filename = filename[: match.start()]
        directory = file_path.parent

        # 查找所有相关的分割文件
        split_files = []
        pattern = (
            re.escape(base_filename) + re.escape(SPLIT_FILE_EXTENSION) + r"(\d{3})"
        )

        for file in directory.iterdir():
            if file.is_file():
                match = re.match(pattern, file.name)
                if match:
                    part_num = int(match.group(1))
                    split_files.append((part_num, file))

        if not split_files:
            print(f"[Error]: No split files found for base: {base_filename}")
            return None, None

        # 按编号排序
        split_files.sort(key=lambda x: x[0])
        sorted_files = [str(file) for _, file in split_files]

        # 生成合并后的文件名（添加.merged后缀）
        merged_filename = base_filename + ".merged"
        merged_file_path = directory / merged_filename

        return sorted_files, str(merged_file_path)

    except Exception as e:
        print(f"[Error]: Failed to find split files: {str(e)}")
        return None, None


def merge_files(split_files, output_file):
    """
    合并分割文件
    """
    try:
        print(f"[Merge]: Merging {len(split_files)} files into {output_file}")

        with open(output_file, "wb") as outfile:
            for i, split_file in enumerate(split_files, 1):
                print(f"[Merge]: Processing part {i}/{len(split_files)}: {split_file}")

                with open(split_file, "rb") as infile:
                    while True:
                        chunk = infile.read(8192)  # 8KB chunks
                        if not chunk:
                            break
                        outfile.write(chunk)

        # 验证合并后的文件大小
        total_size = sum(os.path.getsize(f) for f in split_files)
        merged_size = os.path.getsize(output_file)

        if total_size == merged_size:
            print(
                f"[Success]: Files merged successfully! Total size: {merged_size/1024/1024:.2f}MB"
            )
            return True
        else:
            print(
                f"[Warning]: Size mismatch! Expected: {total_size}, Got: {merged_size}"
            )
            return False

    except Exception as e:
        print(f"[Error]: Failed to merge files: {str(e)}")
        return False


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

    except Exception as e:
        print(f"[Error] Failed to update .gitignore: {str(e)}")


def find_git_root(start_path=None):
    """
    查找Git根目录
    """
    current_path = start_path or os.getcwd()
    while True:
        git_dir = os.path.join(current_path, ".git")
        if os.path.exists(git_dir) and os.path.isdir(git_dir):
            return current_path
        parent_path = os.path.dirname(current_path)
        if parent_path == current_path:
            return None
        current_path = parent_path


def main():
    if len(sys.argv) < 2:
        print("Usage: python git_file_merge.py <any_split_file>")
        print("Example: python git_file_merge.py large_file.zip.split_part_001")
        sys.exit(1)

    split_file = sys.argv[1]

    # 查找所有相关的分割文件
    split_files, output_file = find_split_files(split_file)
    if not split_files:
        sys.exit(1)

    print(f"[Info]: Found {len(split_files)} split files:")
    for i, file in enumerate(split_files, 1):
        size = os.path.getsize(file) / 1024 / 1024
        print(f"  {i:2d}. {file} ({size:.2f}MB)")

    # 检查输出文件是否已存在
    if os.path.exists(output_file):
        response = input(
            f"[Warning]: Output file {output_file} already exists. Overwrite? (y/N): "
        )
        if response.lower() != "y":
            print("[Info]: Merge cancelled")
            sys.exit(0)

    # 合并文件
    if merge_files(split_files, output_file):
        # 将合并后的文件添加到.gitignore
        git_root = find_git_root()
        if git_root:
            # 计算相对于git根目录的路径
            try:
                output_path = Path(output_file)
                git_root_path = Path(git_root)
                relative_path = output_path.relative_to(git_root_path)
                add_to_gitignore(str(relative_path), git_root)
            except ValueError:
                # 如果文件不在git仓库内，使用文件名
                add_to_gitignore(output_path.name, git_root)

        print(f"[Complete]: Merged file created: {output_file}")
    else:
        print("[Error]: Failed to merge files")
        sys.exit(1)


if __name__ == "__main__":
    main()
