#Requires AutoHotkey v2.0

MoveCursorRight() {
    Send "{Right}"
}

MoveCursorLeft() {
    Send "{Left}"
}

MoveCursorUp() {
    Send "{Up}"
}

MoveCursorDown() {
    Send "{Down}"
}

MinimizeTargetWindow() {
    global g_TargetWindowHwnd
    WinMinimize(g_TargetWindowHwnd)
}

ToggleMaximizeWindow() {
    global g_TargetWindowHwnd
    if (WinGetMinMax(g_TargetWindowHwnd) == 1) {
        WinRestore(g_TargetWindowHwnd)
    } else {
        WinMaximize(g_TargetWindowHwnd)
    }
}

IncreaseSystemVolume() {
    Send "{Volume_Up}"
}

DecreaseSystemVolume() {
    Send "{Volume_Down}"
}

SwitchToNextTab() {
    Send "^{Tab}"
}

SwitchToPreviousTab() {
    Send "^+{Tab}"
}

PlayNextMedia() {
    Send "{Media_Next}"
}

PlayPreviousMedia() {
    Send "{Media_Prev}"
}
