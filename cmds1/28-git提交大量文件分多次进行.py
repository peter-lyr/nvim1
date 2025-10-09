# python实现git提交大量文件分多次进行
# python命令传入一个参数用于git commit -F
# 如果出现大量未提交的文件，则先提交修改的文件，在提交未提交的文件
# 如果未提交的文件总大小超过500M，则多次提交，每次提交，按文件大小从小到大去git add，等待git push命令输出的结果，如果失败则重试，重试5次都失败则退出程序，成功则进入下一次提交
# 如果有文件超过500M，则跳过，并警告


# 接收一个命令行参数作为git commit -F的提交信息文件
# 区分处理已修改文件和未跟踪文件，先提交已修改文件
# 对文件大小进行检查：
# 单个文件超过 500MB 会被跳过并显示警告
# 总大小超过 500MB 时会分多次提交
# 每次提交按文件大小从小到大排序
# 包含错误处理和重试机制：
# git push操作失败时会重试，最多 5 次
# 任何步骤失败都会显示错误信息并退出程序
# 使用方法：
# bash
# python git_batch_commit.py commit_message.txt
# 其中commit_message.txt是包含你的提交信息的文件。脚本会自动处理所有未提交文件，按照设定的规则分批次提交和推送。

# 已合并到nvim1\leader\leader_g\py\01-git-add-commit-push.py
# 有报错


import os
import subprocess
import sys
import argparse


def run_command(command, check=True):
    """执行shell命令并返回结果"""
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=check,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr


def get_uncommitted_files():
    """获取所有未提交的文件（已修改和未跟踪）"""
    # 获取已修改的文件
    success, modified = run_command("git diff --name-only")
    # 获取未跟踪的文件
    success, untracked = run_command("git ls-files --others --exclude-standard")

    modified_files = [f.strip() for f in modified.splitlines() if f.strip()]
    untracked_files = [f.strip() for f in untracked.splitlines() if f.strip()]

    return modified_files, untracked_files


def get_file_size(file_path):
    """获取文件大小（字节）"""
    try:
        return os.path.getsize(file_path)
    except OSError:
        print(f"警告：无法获取文件大小 {file_path}")
        return 0


def commit_files(files, commit_msg_file):
    """提交指定文件"""
    if not files:
        print("没有文件需要提交")
        return True

    # 添加文件
    files_quoted = [f'"{f}"' for f in files]
    add_cmd = f'git add {" ".join(files_quoted)}'
    success, output = run_command(add_cmd)
    if not success:
        print(f"添加文件失败: {output}")
        return False

    # 提交文件
    commit_cmd = f"git commit -F {commit_msg_file}"
    success, output = run_command(commit_cmd)
    if not success:
        print(f"提交失败: {output}")
        return False

    print(f"成功提交 {len(files)} 个文件")
    return True


def push_with_retry(max_retries=5):
    """推送提交，失败时重试"""
    for i in range(max_retries):
        print(f"正在推送 (尝试 {i+1}/{max_retries})...")
        success, output = run_command("git push")
        if success:
            print("推送成功")
            return True
        print(f"推送失败: {output}")
        if i < max_retries - 1:
            print("等待重试...")

    print(f"达到最大重试次数 ({max_retries})，推送失败")
    return False


def main():
    parser = argparse.ArgumentParser(description="批量提交Git文件")
    parser.add_argument("commit_msg_file", help="包含提交信息的文件路径")
    args = parser.parse_args()

    commit_msg_file = args.commit_msg_file
    if not os.path.exists(commit_msg_file):
        print(f"错误：提交信息文件 {commit_msg_file} 不存在")
        sys.exit(1)

    # 500MB in bytes
    MAX_BATCH_SIZE = 500 * 1024 * 1024
    MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024

    # 获取未提交文件
    modified_files, untracked_files = get_uncommitted_files()
    print(
        f"发现 {len(modified_files)} 个已修改文件，{len(untracked_files)} 个未跟踪文件"
    )

    # 先提交已修改的文件
    if modified_files:
        print(f"正在提交 {len(modified_files)} 个已修改文件...")
        if commit_files(modified_files, commit_msg_file):
            if not push_with_retry():
                print("提交已修改文件后推送失败，程序退出")
                sys.exit(1)
        else:
            print("提交已修改文件失败，程序退出")
            sys.exit(1)

    # 处理未跟踪文件
    if not untracked_files:
        print("没有未跟踪文件需要提交")
        sys.exit(0)

    # 检查文件大小并过滤过大文件
    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            print(
                f"警告：文件 {file} 大小为 {file_size/1024/1024:.2f}MB，超过500MB，已跳过"
            )
            continue
        filtered_files.append((file, file_size))

    # 按文件大小从小到大排序
    filtered_files.sort(key=lambda x: x[1])
    print(f"过滤后剩余 {len(filtered_files)} 个未跟踪文件需要提交")

    # 分批次提交
    current_batch = []
    current_size = 0

    for file, size in filtered_files:
        # 如果添加当前文件会超过批次大小，则提交当前批次
        if current_size + size > MAX_BATCH_SIZE:
            if current_batch:
                print(
                    f"提交当前批次 ({len(current_batch)} 个文件，总大小 {current_size/1024/1024:.2f}MB)..."
                )
                if commit_files(current_batch, commit_msg_file):
                    if not push_with_retry():
                        print("推送失败，程序退出")
                        sys.exit(1)
                else:
                    print("提交失败，程序退出")
                    sys.exit(1)

                # 重置批次
                current_batch = []
                current_size = 0

        current_batch.append(file)
        current_size += size

    # 提交最后一批文件
    if current_batch:
        print(
            f"提交最后一批 ({len(current_batch)} 个文件，总大小 {current_size/1024/1024:.2f}MB)..."
        )
        if commit_files(current_batch, commit_msg_file):
            if not push_with_retry():
                print("推送失败，程序退出")
                sys.exit(1)
        else:
            print("提交失败，程序退出")
            sys.exit(1)

    print("所有文件提交完成")


if __name__ == "__main__":
    main()
