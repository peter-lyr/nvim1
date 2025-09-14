@echo off
:: Use default encoding
chcp 437 >nul

git status

:: Check if in a Git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if not %errorlevel% equ 0 (
    echo Error: Current directory is not a Git repository
    pause
    exit /b 1
)

:: Prompt for commit message
echo Enter commit message:
set /p msg=

:: Check for empty message
if "%msg%"=="" (
    echo Commit message cannot be empty!
    pause
    exit /b 1
)

:: Execute Git commands
echo Adding files...
git add .

echo Committing changes...
git commit -m "%msg%"

echo Pulling latest from remote...
git pull origin main

echo Pushing to remote...
git push origin main

echo Operation completed
pause
