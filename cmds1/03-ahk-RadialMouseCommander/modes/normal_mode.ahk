#Requires AutoHotkey v2.0

global g_CurrentMode := "normal"

InitializeNormalModeActions() {
    ModeActionsSetDo("normal",
        ;;以下3个最常用
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", SendAfterActivate.Bind("{Esc}")],
        ;;各种模式
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
        "000U", ["窗口激活模式", EnterWindowActivateMode],
        ;;待替换
        "000D", ["向下移动光标", Send.Bind("{Down}")],
        "000L", ["向左移动光标", Send.Bind("{Left}")],
        "000R", ["向右移动光标", Send.Bind("{Right}")],
        ;;配置
        "001R", ["切换菜单提示", ToggleUpdateRadialMenuTooltipEn],
        "001RU", ["切换2秒提示", ToggleShowTimedTooltipEn],
        "001RD", ["切换画圆", ToggleRadialMenuGuiEn],
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

RButtonDo() {
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    InitRadialMenuTooltip()
}

^!r:: {
    Reload
}

^!c:: {
    CompileMouseAndRun()
}

^!t:: {
    ToggleToOExe()
}

#HotIf not RemoteDesktopActiveOrRButtonPressed()

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
    MouseGetPos(&x)
    if (x >= 0 && x <= 10) {
        if (IsDoubleClick()) {
            ToggleToOExe()
        }
    }
}

~MButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
}

~WheelUp:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonStateInc()
        return
    }
}

~WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonStateDec()
        return
    }
}

#HotIf
