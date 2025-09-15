import os
import sys
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("require 1 arg like commit_info.txt")
        os._exit(1)
    git_commit_txt = sys.argv[1]
    os.system("cd")
    os.system("git add -A")
    print(f"git commit -F {git_commit_txt}")
    os.system(f"git commit -F {git_commit_txt}")
    os.system("git push")
