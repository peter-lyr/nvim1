#Requires AutoHotkey v2.0

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

ClickAtTargetPosition() {
    global g_TargetClickX, g_TargetClickY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickX, g_TargetClickY, "Left")
    MouseMove(originalX, originalY, 0)
}
