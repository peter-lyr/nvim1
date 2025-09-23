#Requires AutoHotkey v2.0
DetectHiddenWindows True

#Include %A_ScriptDir%\circle.ahk
#Include %A_ScriptDir%\window.ahk
#Include %A_ScriptDir%\window_control.ahk

; 界面相关变量
global g_CircleGui := ""
global g_CircleHwnd := 0
global g_CircleRadius := 50
global g_CircleCenterX := 0
global g_CircleCenterY := 0
global g_TargetWindowHwnd := 0

; 鼠标状态变量
global g_LeftClickState := 0, g_MiddleClickState := 0, g_WheelState := 0
global g_MaxLeftClickStates := 1, g_MaxMiddleClickStates := 1, g_MaxWheelStates := 1

; 模式管理
global g_CurrentMode := "normal"
global g_LastDisplayContent := ""

; 方向映射表
global g_DirectionArrowMap := Map(
    "R", "→",
    "RD", "↘",
    "D", "↓",
    "LD", "↙",
    "L", "←",
    "LU", "↖",
    "U", "↑",
    "RU", "↗"
)

global g_DirectionNameMap := Map(
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
global g_ActionFunctionMaps := Map()

InitializeActionMappings() {
    global g_ActionFunctionMaps
    normalModeMap := Map()
    normalModeMap["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    normalModeMap["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeMap["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeMap["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeMap["000RU"] := ["切换最大化窗口", ToggleMaximizeWindow]
    normalModeMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    normalModeMap["000LU"] := ["窗口控制模式", SwitchToWindowControlMode]
    g_ActionFunctionMaps["normal"] := normalModeMap
}

SwitchToNormalMode() {
    global g_CurrentMode := "normal"
    ShowTemporaryTooltip("已恢复原始热键模式")
}

OnRButtonPress() {
    global g_LastDisplayContent := ""
    CaptureWindowUnderCursor()
    ShowCircleGuiAtMousePosition()
    SetTimer(UpdateOperationDisplayTooltip, 10)
}

#HotIf g_CurrentMode = "normal"

~LButton:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        CycleLeftClickState()
        return
    }
}

~MButton:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        CycleMiddleClickState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        CycleWheelState()
        return
    }
}
#HotIf

RButton:: {
    OnRButtonPress()
}

RButton Up:: {
    SetTimer(UpdateOperationDisplayTooltip, 0)
    ToolTip()
    global g_LastDisplayContent := ""
    HideCircleGui()
    if (IsMouseInsideCircle()) {
        Click "Right"
    } else {
        ExecuteCurrentOperation()
    }
}

InitializeActionMappings()
ShowCircleGuiAtMousePosition()
HideCircleGui()

^Ins::ExitApp
