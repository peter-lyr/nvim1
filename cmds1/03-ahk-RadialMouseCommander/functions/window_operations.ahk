; 窗口操作相关函数

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
    global g_TargetClickPosX, g_TargetClickPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickPosX, g_TargetClickPosY, "Left")
    MouseMove(originalX, originalY, 0)
}

ProcessWindowMovement() {
    global g_WindowMoveInfo
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessWindowMovement, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveInfo.startMouseX
    deltaY := currentMouseY - g_WindowMoveInfo.startMouseY
    newX := g_WindowMoveInfo.startWinX + deltaX
    newY := g_WindowMoveInfo.startWinY + deltaY
    WinMove newX, newY, , , g_WindowMoveInfo.win
}

ProcessWindowResizing() {
    global g_WindowResizeInfo
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessWindowResizing, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeInfo.startMouseX
    deltaY := currentMouseY - g_WindowResizeInfo.startMouseY
    newX := g_WindowResizeInfo.startWinX
    newY := g_WindowResizeInfo.startWinY
    newWidth := g_WindowResizeInfo.startWinW
    newHeight := g_WindowResizeInfo.startWinH
    switch g_WindowResizeInfo.resizeEdge {
        case "top-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeInfo.win
}
