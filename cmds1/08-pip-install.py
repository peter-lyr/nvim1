import os
def pip_install(plugin):
    os.system(f'pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com {plugin}')
# pip_install('neovim')
