@echo off
cd %~dp0
set exe=mouse.exe
taskkill /f /im %exe%
Ahk2Exe.exe /icon m.ico /base "C:\Program Files\AutoHotKey\v2\AutoHotkey64.exe" /in main.ahk /out %exe% /compress 1
start /b /min %exe%
pause
exit
