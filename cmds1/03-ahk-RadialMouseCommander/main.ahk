#Requires AutoHotkey v2.0
DetectHiddenWindows True

; 包含所有模块文件
#Include %A_ScriptDir%\lib\radial-menu-gui.ahk
#Include %A_ScriptDir%\lib\window-management.ahk
#Include %A_ScriptDir%\lib\mode-management.ahk
#Include %A_ScriptDir%\lib\direction-utils.ahk
#Include %A_ScriptDir%\lib\tooltip-display.ahk
#Include %A_ScriptDir%\config\mode-actions.ahk

; 全局变量声明
global g_RadialMenuGui := ""
global g_RadialMenuGuiHwnd := 0
global g_RadialMenuRadius := 50
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_TargetWindowHwnd := 0
global g_TargetClickPosX := 0
global g_TargetClickPosX := 0

global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1

global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

global g_CurrentMode := "normal"
global g_PreviousTooltip := ""

; 主热键定义
RButton:: {
    global g_PreviousTooltip := ""
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    SetTimer(UpdateRadialMenuTooltip, 10)
}

RButton Up:: {
    SetTimer(UpdateRadialMenuTooltip, 0)
    ToolTip()
    global g_PreviousTooltip := ""
    HideRadialMenu()
    if (IsCursorInsideRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedAction()
    }
}

#HotIf g_CurrentMode = "normal"
~LButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
}

~MButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
}
#HotIf

; 初始化
InitializeModeActionMappings()
DisplayRadialMenuAtCursor()
HideRadialMenu()

^Ins::ExitApp
