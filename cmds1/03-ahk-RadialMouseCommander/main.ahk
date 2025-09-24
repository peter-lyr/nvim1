#Requires AutoHotkey v2.0
DetectHiddenWindows True

; 包含其他文件
#Include modes/normal_mode.ahk
#Include modes/window_control_mode.ahk
#Include modes/window_control_mode2.ahk
#Include functions/radial_menu.ahk
#Include functions/tooltips.ahk
#Include functions/window_operations.ahk
#Include functions/mode_management.ahk

; 初始化
InitializeModeActionMappings()
DisplayRadialMenuAtCursor()
HideRadialMenu()

; 热键
^Ins::ExitApp
