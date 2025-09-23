#Requires AutoHotkey v2.0
DetectHiddenWindows True

#Include %A_ScriptDir%\circle.ahk
#Include %A_ScriptDir%\window.ahk
#Include %A_ScriptDir%\window_control.ahk

global g_CircleGui := ""
global g_CircleHwnd := 0
global g_CircleRadius := 50
global g_CircleCenterX := 0
global g_CircleCenterY := 0
global g_TargetWindowHwnd := 0

global g_LeftClickState := 0, g_MiddleClickState := 0, g_WheelState := 0
global g_MaxLeftClickStates := 1, g_MaxMiddleClickStates := 1, g_MaxWheelStates := 1

global g_CurrentMode := "normal"

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

global g_ActionFunctionMap := Map()

InitializeActionMappings() {
    global g_ActionFunctionMap
    g_ActionFunctionMap["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    g_ActionFunctionMap["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    g_ActionFunctionMap["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    g_ActionFunctionMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    g_ActionFunctionMap["000RU"] := ["切换最大化窗口", ToggleMaximizeWindow]
    g_ActionFunctionMap["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    g_ActionFunctionMap["000LU"] := ["窗口控制模式", WindowControlMode]
}

RButtonDo() {
    global g_LastDisplayContent := ""
    CaptureWindowUnderCursor()
    ShowCircleAtMousePosition()
    SetTimer(UpdateOperationDisplay, 10)
}

#HotIf g_CurrentMode = "normal"
RButton:: {
    RButtonDo()
}

RButton Up:: {
    SetTimer(UpdateOperationDisplay, 0)
    ToolTip()
    global g_LastDisplayContent := ""
    HideCircleInterface()
    if (IsMouseWithinCircle()) {
        Click "Right"
    } else {
        ExecuteCurrentOperation()
    }
}

~LButton:: {
    if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
        ChangeLeftClickState()
        return
    }
}

~MButton:: {
    if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
        ChangeMiddleClickState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
        ChangeWheelState()
        return
    }
}
#HotIf

InitializeActionMappings()

ShowCircleAtMousePosition()
HideCircleInterface()

^Ins::ExitApp
