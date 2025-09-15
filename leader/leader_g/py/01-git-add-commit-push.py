import os
import sys
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("require 1 arg like commit_info.txt")
        os._exit(1)
    print("222222222")
    git_commit_txt = sys.argv[1]
    print("222222223")
    os.system("git add -A")
    print("222222224")
    os.system(f"git commit -F {git_commit_txt}")
    print("222222225")
    os.system("git push")
    print("222222226")
