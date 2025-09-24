; 普通模式配置

; 初始化普通模式动作映射
InitializeNormalModeActions() {
    global g_ModeActionMappings
    normalModeActions := Map()
    normalModeActions["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    normalModeActions["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeActions["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeActions["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    normalModeActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    normalModeActions["000LU"] := ["窗口控制模式", EnterWindowControlMode]
    g_ModeActionMappings["normal"] := normalModeActions
}

; 全局热键（不在任何模式条件下）
RButton:: {
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    InitRadialMenuTooltip()
}

RButton Up:: {
    ExitRadialMenuTooltip()
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
