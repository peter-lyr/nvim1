import os


def echo(text):
    os.system(f"chcp 65001>nul&echo {text}".strip() + "\r")


if __name__ == "__main__":
    os.system("chcp 65001>nul & git status")
    echo(os.getcwd())
