import os
import tempfile
temp_dir = tempfile.gettempdir()
content = """plugins.lua里不要有require 'f'"""
git_commit_txt = os.path.join(temp_dir, 'git_commit.txt')
with open(git_commit_txt, 'wb') as f:
    f.write(content.encode('utf-8'))
os.system("git add -A")
os.system(f"git commit -F {git_commit_txt}")
os.system("git push")
