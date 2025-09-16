import os

cur_dir = os.path.dirname(__file__)  # 当前文件所在目录
print(cur_dir)
up_dir = os.path.split(cur_dir)[0]  # 上级目录
print(up_dir)
tail = os.path.split(cur_dir)[1]  # 上级目录
print(tail)
