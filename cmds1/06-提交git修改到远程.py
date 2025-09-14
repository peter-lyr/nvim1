import os
import tempfile
temp_dir = tempfile.gettempdir()
content = "leader r .: 用系统的方式打开当前文件"
git_commit_txt = os.path.join(temp_dir, 'git_commit.txt')
with open(git_commit_txt, 'wb') as f:
    f.write(content.encode('utf-8'))
os.system("git add .")
os.system(f"git commit -F {git_commit_txt}")
os.system("git push")
