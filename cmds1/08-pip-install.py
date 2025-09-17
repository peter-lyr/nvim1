import os


def pip_install(plugin):
    os.system(
        f"pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com {plugin}"
    )


# pip_install('neovim') # nvim-qt的依赖
# pip_install('pyperclip') # 复制文本到系统剪贴板
# pip_install('pynput')
# pip_install('ipython')
# pip_install("pywin32")
