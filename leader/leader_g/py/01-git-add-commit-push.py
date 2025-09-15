import os
import sys
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("require 1 arg like commit_info.txt")
        os._exit(1)
    git_commit_txt = sys.argv[1]
    with open(git_commit_txt, 'rb') as f:
        lines = f.readlines()
    with open(git_commit_txt, 'wb') as f:
        for line in lines:
            l = line.strip()
            if l[:2] == '# ':
                continue
            if not l:
                continue
            f.write(line)
    os.system("cd")
    os.system("git add -A")
    os.system(f"git commit -F {git_commit_txt}")
    os.system("git push")
