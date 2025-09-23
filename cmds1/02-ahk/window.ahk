#Requires AutoHotkey v2.0

ActivateTargetWindow() {
    global g_ActiveWindowHwnd
    WinActivate(g_ActiveWindowHwnd)
}

MinimizeActiveWindow() {
    global g_ActiveWindowHwnd
    WinMinimize(g_ActiveWindowHwnd)
}

ToggleWindowMaximize() {
    global g_ActiveWindowHwnd
    if (WinGetMinMax(g_ActiveWindowHwnd) == 1) {
        WinRestore(g_ActiveWindowHwnd)
    } else {
        WinMaximize(g_ActiveWindowHwnd)
    }
}

