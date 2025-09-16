import os

if __name__ == "__main__":
    print(os.getcwd())
    os.chdir(os.path.expanduser(r'~\Dp1\lazy\nvim1'))
    os.system("git pull")
