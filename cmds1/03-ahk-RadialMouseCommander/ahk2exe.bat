@echo off
cd %~dp0
set exe=mouse1.exe
taskkill /f /im %exe%
REM Ahk2Exe.exe /icon ..ico /base "C:\Program Files\AutoHotKey\v2\AutoHotkey32.exe" /in main.ahk /out %exe% /compress 1
Ahk2Exe.exe /base "C:\Program Files\AutoHotKey\v2\AutoHotkey32.exe" /in main.ahk /out %exe% /compress 1
start /b /min %exe%
exit
