; 普通模式配置

#Requires AutoHotkey v2.0

global g_CurrentMode := "normal"

; 初始化普通模式动作映射
InitializeNormalModeActions() {
    ModeActionsSetDo("normal",
        "000U", ["窗口激活模式", EnterWindowActivateMode],
        "000D", ["向下移动光标", Send.Bind("{Down}")],
        "000L", ["向左移动光标", Send.Bind("{Left}")],
        "000R", ["向右移动光标", Send.Bind("{Right}")],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LU", ["窗口控制模式", EnterWindowControlMode],
        "100LU", ["窗口控制模式2", EnterWindowControlMode2],
        "010R", ["切换菜单提示", ToggleUpdateRadialMenuTooltipEn],
        "010RU", ["切换2秒提示", ToggleShowTimedTooltipEn],
    )
}

ModeActionsSetDo(modeName, actions*) {
    global g_ModeActionMappings
    global g_CurrentMode := modeName
    actionsMap := Map()
    actionsMap.Set(actions*)
    g_ModeActionMappings[g_CurrentMode] := actionsMap
}

ModeActionsSet(modeName, actions*) {
    ModeActionsSetDo(modeName, actions*)
    ShowTimedTooltip("已切换到" g_CurrentMode "模式")
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复到normal模式")
}

^!t:: {
    Global g_CurrentMode
    if (g_CurrentMode = "null") {
        g_CurrentMode := "normal"
    } else {
        g_CurrentMode := "null"
    }
    ShowTimedTooltip("g_CurrentMode: " g_CurrentMode)
}

RButtonDo() {
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    InitRadialMenuTooltip()
}

#HotIf g_CurrentMode != "null"

RButton:: {
    ResetButtonStates()
    RButtonDo()
}

~LButton & RButton:: {
    Global g_LeftButtonState := 1
    RButtonDo()
}

RButton Up:: {
    ExitRadialMenuTooltip()
    HideRadialMenu()
    if (IsCursorInsideRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedAction()
    }
    ResetButtonStates()
}

#HotIf

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
