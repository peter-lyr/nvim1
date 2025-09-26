; 普通模式配置

#Requires AutoHotkey v2.0

global g_CurrentMode := "normal"

; 初始化普通模式动作映射
InitializeNormalModeActions() {
    global g_ModeActionMappings
    normalModeActions := Map()
    normalModeActions["000U"] := ["窗口激活模式", EnterWindowActivateMode]
    normalModeActions["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeActions["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeActions["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeActions["000LD"] := ["Esc", Send.Bind("{Esc}")]
    normalModeActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    normalModeActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    normalModeActions["000LU"] := ["窗口控制模式", EnterWindowControlMode]
    normalModeActions["100LU"] := ["窗口控制模式2", EnterWindowControlMode2]
    normalModeActions["010R"] := ["切换菜单提示", ToggleUpdateRadialMenuTooltipEn]
    normalModeActions["010RU"] := ["切换2秒提示", ToggleShowTimedTooltipEn]
    g_ModeActionMappings["normal"] := normalModeActions
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复原始热键模式")
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
