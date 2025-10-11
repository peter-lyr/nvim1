@echo off
cd %~dp0
gcc -o git-auto-commit.exe git-auto-commit.c
pause
