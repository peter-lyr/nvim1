; 模式管理功能

ActivateTargetWindow() {
    global g_TargetWindowHwnd
    WinActivate(g_TargetWindowHwnd)
}

MinimizeTargetWindow() {
    global g_TargetWindowHwnd
    WinMinimize(g_TargetWindowHwnd)
}

ToggleTargetWindowMaximize() {
    global g_TargetWindowHwnd
    if (WinGetMinMax(g_TargetWindowHwnd) == 1) {
        WinRestore(g_TargetWindowHwnd)
    } else {
        WinMaximize(g_TargetWindowHwnd)
    }
}

EnterWindowControlMode() {
    global g_CurrentMode := "window_control"
    windowControlActions := Map()
    windowControlActions["000L"] := ["恢复普通模式", EnterNormalMode]
    windowControlActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    windowControlActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    windowControlActions["000U"] := ["激活窗口", ActivateTargetWindow]
    windowControlActions["000D"] := ["按退出键", Send.Bind("{Esc}")]
    windowControlActions["000LU"] := ["单击目标", ClickAtTargetPosition]
    windowControlActions["000LD"] := ["单击目标", ClickAtTargetPosition]
    windowControlActions["000R"] := ["单击目标", ClickAtTargetPosition]
    g_ModeActionMappings["window_control"] := windowControlActions
    ShowTimedTooltip("已切换到窗口控制模式")
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复原始热键模式")
}

ClickAtTargetPosition() {
    global g_TargetClickPosX, g_TargetClickPosX
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickPosX, g_TargetClickPosX, "Left")
    MouseMove(originalX, originalY, 0)
}

GetCurrentModeActionMap() {
    global g_ModeActionMappings, g_CurrentMode
    if (!g_ModeActionMappings.Has(g_CurrentMode)) {
        return g_ModeActionMappings["normal"]
    }
    return g_ModeActionMappings[g_CurrentMode]
}

ExecuteSelectedAction() {
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    if (actionMap.Has(stateKey)) {
        actionInfo := actionMap[stateKey]
        actionFunction := actionInfo[2]
        try {
            actionFunction()
        } catch as e {
            ShowTimedTooltip("执行操作时出错: " e.Message " [" actionInfo[1] "]")
        }
    } else {
        ShowTimedTooltip("未定义的操作: " stateKey)
    }
}

CycleLeftButtonState() {
    global g_LeftButtonState, g_MaxLeftButtonStates
    g_LeftButtonState := Mod(g_LeftButtonState + 1, g_MaxLeftButtonStates + 1)
}

CycleMiddleButtonState() {
    global g_MiddleButtonState, g_MaxMiddleButtonStates
    g_MiddleButtonState := Mod(g_MiddleButtonState + 1, g_MaxMiddleButtonStates + 1)
}

CycleWheelButtonState() {
    global g_WheelButtonState, g_MaxWheelButtonStates
    g_WheelButtonState := Mod(g_WheelButtonState + 1, g_MaxWheelButtonStates + 1)
}
