"""
文件合并工具
用法: python git_file_merge.py <任意分割文件>
"""

import os
import sys
import re
import random
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
            return None, None, None

        # 提取基础文件名（去掉分割后缀和编号）
        filename = file_path.name
        pattern = re.escape(SPLIT_FILE_EXTENSION) + r"\d{3}$"
        match = re.search(pattern, filename)

        if not match:
            print(f"[Error]: Not a valid split file: {any_split_file}")
            return None, None, None

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
            return None, None, None

        # 按编号排序
        split_files.sort(key=lambda x: x[0])
        sorted_files = [str(file) for _, file in split_files]

        # 生成合并后的文件名（添加.merged后缀）
        merged_filename = base_filename + ".merged"
        merged_file_path = directory / merged_filename

        return sorted_files, str(merged_file_path), str(directory)

    except Exception as e:
        print(f"[Error]: Failed to find split files: {str(e)}")
        return None, None, None


def merge_files(split_files, output_file):
    """
    合并分割文件
    """
    try:
        print(f"[Merge]: Merging {len(split_files)} files into {output_file}")

        total_size = 0
        file_sizes = []

        # 先显示所有文件的大小信息
        print("[Merge]: File sizes:")
        for i, split_file in enumerate(split_files, 1):
            size = os.path.getsize(split_file)
            file_sizes.append(size)
            total_size += size
            print(f"  Part {i:2d}: {split_file} ({size/1024/1024:.2f}MB)")

        print(f"[Merge]: Total size: {total_size/1024/1024:.2f}MB")

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


def add_to_local_gitignore(file_pattern, local_dir):
    """
    在文件同目录下创建.gitignore文件，添加合并文件
    """
    gitignore_path = os.path.join(local_dir, ".gitignore")

    try:
        # 读取现有的.gitignore内容
        existing_patterns = set()
        if os.path.exists(gitignore_path):
            with open(gitignore_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        existing_patterns.add(line)

        # 如果合并文件模式不存在，则添加
        merged_pattern = f"{file_pattern}.merged"
        if merged_pattern not in existing_patterns:
            with open(gitignore_path, "a", encoding="utf-8") as f:
                f.write(f"\n{merged_pattern}\n")
            print(f"[GitIgnore] Added {merged_pattern} to {gitignore_path}")

    except Exception as e:
        print(f"[Error] Failed to update local .gitignore: {str(e)}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python git_file_merge.py <any_split_file>")
        print("Example: python git_file_merge.py large_file.zip.split_part_001")
        sys.exit(1)

    split_file = sys.argv[1]

    # 查找所有相关的分割文件
    split_files, output_file, file_dir = find_split_files(split_file)
    if not split_files:
        sys.exit(1)

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
        # 将合并后的文件添加到同目录的.gitignore
        output_filename = os.path.basename(output_file)
        base_filename = output_filename.replace(".merged", "")
        add_to_local_gitignore(base_filename, file_dir)

        print(f"[Complete]: Merged file created: {output_file}")
        print(
            f"[Complete]: Added {base_filename}.merged to {os.path.join(file_dir, '.gitignore')}"
        )
    else:
        print("[Error]: Failed to merge files")
        sys.exit(1)


if __name__ == "__main__":
    main()
