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
            # print(line.strip().decode("utf-8"))
            push_allow = True
    if not push_allow:
        os.system(f"echo commit file is empty: {git_commit_txt}")
        os._exit(2)
    os.system("chcp 65001>nul & git add -A")
    os.system(f"git commit -F {git_commit_txt}")
    print("=========commit info:=========")
    os.system(f"git log -n 1")  # 打印当前commit
    print("==============================")
    os.system("git push")
