#Requires AutoHotkey v2.0
DetectHiddenWindows True

#Include %A_ScriptDir%\circle.ahk
#Include %A_ScriptDir%\example.ahk

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
    g_ActionFunctionMap["000R"] := "MoveCursorRight"
    g_ActionFunctionMap["000RD"] := "MinimizeTargetWindow"
    g_ActionFunctionMap["000RU"] := "ToggleMaximizeWindow"
    g_ActionFunctionMap["000D"] := "MoveCursorDown"
    g_ActionFunctionMap["000L"] := "MoveCursorLeft"
    g_ActionFunctionMap["000U"] := "MoveCursorUp"
    g_ActionFunctionMap["000LU"] := "ExampleFunction1"
    g_ActionFunctionMap["000LD"] := "ExampleFunction2"
    g_ActionFunctionMap["100R"] := "IncreaseSystemVolume"
    g_ActionFunctionMap["100L"] := "DecreaseSystemVolume"
    g_ActionFunctionMap["010U"] := "SwitchToNextTab"
    g_ActionFunctionMap["010D"] := "SwitchToPreviousTab"
    g_ActionFunctionMap["001R"] := "PlayNextMedia"
    g_ActionFunctionMap["001L"] := "PlayPreviousMedia"
}

RButtonDo() {
    global g_LastDisplayContent := ""
    CaptureWindowUnderCursor()
    ShowCircleAtMousePosition()
    SetTimer(UpdateOperationDisplay, 150)
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
