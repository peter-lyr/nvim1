; 普通模式配置

#Requires AutoHotkey v2.0

global g_CurrentMode := "normal"

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
    normalModeActions["100LU"] := ["窗口控制模式2", EnterWindowControlMode2]
    g_ModeActionMappings["normal"] := normalModeActions
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复原始热键模式")
}

; 全局热键（不在任何模式条件下）
RButton:: {
    ResetButtonStates()
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
    ResetButtonStates()
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
