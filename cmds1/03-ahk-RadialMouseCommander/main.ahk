#Requires AutoHotkey v2.0

; 包含其他文件
#Include menus/normal_menu.ahk
#Include modes/normal_mode.ahk
#Include modes/window_control_mode.ahk
#Include modes/window_control_mode2.ahk
#Include modes/window_activate_mode.ahk
#Include functions/radial_menu.ahk
#Include functions/tooltips.ahk
#Include functions/window_operations.ahk
#Include functions/window_activations.ahk
#Include hotkeys/window_operations.ahk

; 初始化
InitializeNormalModeActions()
DisplayRadialMenuAtCursor()
HideRadialMenu()

; 热键
^Ins::ExitApp
