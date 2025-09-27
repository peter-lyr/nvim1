#Requires AutoHotkey v2.0

^\:: {
    MouseGetPos , , &windowUnderCursor
    winTitle := WinGetProcessName(windowUnderCursor)
    winPID := WinGetPID(windowUnderCursor)
    tooltip(winTitle " - " winPID)
    SetTimer(Tooltip, -2000)
}

^+\:: {
    ExitApp
}
