@echo off
REM import os
REM def run_print_cmd(cmd):
REM     print(f"+++++ {cmd}")
REM     os.system(cmd)

REM repo = ''
REM public = 'public'
REM root_tail = ''
REM path = ''

REM # # 没有.git
REM # cmds = f'''
REM # git init
REM # git add .
REM # git commit -m "s1"
REM # gh repo create {repo} --{public} --description "{root_tail}/{path}" --source=. --remote=origin
REM # git branch -M main
REM # git remote add origin git@github.com:peter-lyr/test-2.git
REM # git push -u origin main
REM # '''

git init
git add .
git commit -m "s1"
REM gh repo create nvim1 --public --description "nvim1" --source=. --remote=origin
REM git branch -M main
REM git remote add origin git@github.com:peter-lyr/nvim1.git
REM git push -u origin main

REM # root: C:\Users\depei_liu\AppData\Local\nvim\leader\leader_g
REM # path: lwekj
REM # public: private
REM # name: peter-lyr
REM # root_tail: leader_g
REM # repo: lwekj

REM # for cmd in cmds.strip().split('\n'):
REM #     print(cmd.strip())

REM # 有.git
REM # git remote add origin git@github.com:peter-lyr/test-2.git
REM # git branch -M main
REM # git push -u origin main

REM # run_print_cmd("git init")
REM # run_print_cmd("git add .")
REM # run_print_cmd('git commit -m "s1"')
REM # run_print_cmd(
REM #     f'gh repo create {repo} --{public} --description "{root_tail}/{path}" --source=. --remote=origin'
REM # )
REM # run_print_cmd('git branch -M main')
REM # run_print_cmd(f'git remote add origin git@github.com:{name}/{repo}')
REM # run_print_cmd("git push -u origin main")
