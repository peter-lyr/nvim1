#Requires AutoHotkey v2.0
DetectHiddenWindows True

#Include %A_ScriptDir%\circle.ahk
#Include %A_ScriptDir%\window.ahk
#Include %A_ScriptDir%\window_control.ahk

; 界面相关变量
global g_RadialMenuGui := ""
global g_RadialMenuHwnd := 0
global g_RadialMenuRadius := 50
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_ActiveWindowHwnd := 0
global g_TargetClickX := 0
global g_TargetClickY := 0

; 鼠标状态变量
global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1

; 窗口操作变量
global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

; 模式管理
global g_CurrentOperationMode := "normal"
global g_LastTooltipContent := ""

; 方向映射表
global g_DirectionToArrowSymbol := Map(
    "R", "→",
    "RD", "↘",
    "D", "↓",
    "LD", "↙",
    "L", "←",
    "LU", "↖",
    "U", "↑",
    "RU", "↗"
)

global g_DirectionToChineseName := Map(
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

InitializeModeActionMappings() {
    global g_ModeActionMappings
    normalModeActions := Map()
    normalModeActions["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    normalModeActions["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeActions["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeActions["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeActions["000RU"] := ["切换最大化窗口", ToggleWindowMaximize]
    normalModeActions["000RD"] := ["最小化窗口", MinimizeActiveWindow]
    normalModeActions["000LU"] := ["窗口控制模式", ActivateWindowControlMode]
    g_ModeActionMappings["normal"] := normalModeActions
}

SwitchToNormalMode() {
    global g_CurrentOperationMode := "normal"
    ShowTemporaryMessage("已恢复原始热键模式")
}

ClickAtTargetPosition() {
    global g_TargetClickX, g_TargetClickY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickX, g_TargetClickY, "Left")
    MouseMove(originalX, originalY, 0)
}

OnRightButtonPressed() {
    global g_LastTooltipContent := ""
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    SetTimer(UpdateRadialMenuTooltip, 10)
}

#HotIf g_CurrentOperationMode = "normal"

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

RButton:: {
    OnRightButtonPressed()
}

RButton Up:: {
    SetTimer(UpdateRadialMenuTooltip, 0)
    ToolTip()
    global g_LastTooltipContent := ""
    HideRadialMenu()
    if (IsCursorInsideRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedAction()
    }
}

InitializeModeActionMappings()
DisplayRadialMenuAtCursor()
HideRadialMenu()

^Ins::ExitApp
