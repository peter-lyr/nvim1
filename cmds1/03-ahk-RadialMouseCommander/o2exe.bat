@echo off
cd %~dp0
set exe=o.exe
taskkill /f /im %exe%
Ahk2Exe.exe /icon o.ico /base "C:\Program Files\AutoHotKey\v2\AutoHotkey64.exe" /in o.ahk /out %exe% /compress 1
start /b /min %exe%
exit
