#Requires AutoHotkey v2.0
DetectHiddenWindows True

; 包含其他文件
#Include modes/normal_mode.ahk
#Include modes/window_control_mode.ahk
#Include functions/radial_menu.ahk
#Include functions/tooltips.ahk
#Include functions/window_operations.ahk
#Include functions/mode_management.ahk

; 全局变量
global g_RadialMenuGui := ""
global g_RadialMenuGuiHwnd := 0
global g_RadialMenuRadius := 50
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_TargetWindowHwnd := 0
global g_TargetClickPosX := 0
global g_TargetClickPosY := 0

; 鼠标状态变量
global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1

; 窗口操作变量
global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

; 模式管理
global g_CurrentMode := "normal"
global g_PreviousTooltip := ""

; 方向映射表
global g_DirectionSymbols := Map(
    "R", "→",
    "RD", "↘",
    "D", "↓",
    "LD", "↙",
    "L", "←",
    "LU", "↖",
    "U", "↑",
    "RU", "↗"
)

global g_DirectionNames := Map(
    "R", "右",
    "RD", "右下",
    "D", "下",
    "LD", "左下",
    "L", "左",
    "LU", "左上",
    "U", "上",
    "RU", "右上"
)

; 动作映射表
global g_ModeActionMappings := Map()

; 初始化
InitializeModeActionMappings()
DisplayRadialMenuAtCursor()
HideRadialMenu()

; 热键
^Ins::ExitApp
