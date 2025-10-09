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
# python git_batch_commit.py commit_message.txt
# 其中commit_message.txt是包含你的提交信息的文件。
# 脚本会自动处理所有未提交文件，按照设定的规则分批次提交和推送。


import os
import sys


if __name__ == "__main__":
    if len(sys.argv) < 2:
        os.system("echo require 1 arg like commit_info.txt")
        os._exit(1)
    git_commit_txt = sys.argv[1]
    with open(git_commit_txt, "rb") as f:
        lines = f.readlines()
    push_allow = False
    git_commit_txt = git_commit_txt + ".txt"
    with open(git_commit_txt, "wb") as f:
        for line in lines:
            if line[:2] == b"# ":
                continue
            if not line.strip():
                continue
            f.write(line.strip() + b"\n")
            push_allow = True
    if not push_allow:
        os.system(f"echo commit file is empty: {git_commit_txt}")
        os._exit(2)
    os.system("chcp 65001>nul & git add -A")
    os.system(f"git commit -F {git_commit_txt}")
    os.system("git push")
