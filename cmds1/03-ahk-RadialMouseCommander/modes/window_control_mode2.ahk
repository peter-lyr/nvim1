#Requires AutoHotkey v2.0

EnterWindowControlMode2() {
    global g_CurrentMode := "window_control2"
    modeName := "窗口控制模式2"
    actionsMap := Map()
    actionsMap["000U"] := ["切换窗口置顶", ToggleTargetWindowTopmost]
    actionsMap["000D"] := ["激活窗口", ActivateTargetWindow]
    actionsMap["000L"] := ["恢复普通模式", EnterNormalMode]
    actionsMap["000R"] := ["单击目标", ClickAtTargetPosition]
    actionsMap["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    actionsMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    actionsMap["000LD"] := ["Esc", Send.Bind("{Esc}")]
    actionsMap["000LU"] := ["窗口控制模式", EnterWindowControlMode]
    global g_ModeActionMappings[g_CurrentMode] := actionsMap
    ShowTimedTooltip("已切换到" modeName)
}

GetScreenWorkArea(winHwnd) {
    monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHwnd, "UInt", 0x2, "Ptr")
    if (monitorHandle = 0) {
        return {left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight}
    }
    monitorInfo := Buffer(40, 0)
    NumPut("UInt", 40, monitorInfo, 0)
    if (DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)) {
        workLeft := NumGet(monitorInfo, 20, "Int")
        workTop := NumGet(monitorInfo, 24, "Int")
        workRight := NumGet(monitorInfo, 28, "Int")
        workBottom := NumGet(monitorInfo, 32, "Int")
        return {left: workLeft, top: workTop, right: workRight, bottom: workBottom}
    }
    return {left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight}
}

ProcessWindowResizing2() {
    global g_WindowResizeInfo, g_CurrentMode
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessWindowResizing2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeInfo.startMouseX
    deltaY := currentMouseY - g_WindowResizeInfo.startMouseY
    workArea := GetScreenWorkArea(g_WindowResizeInfo.win)
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
        case "bottom-right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "center":
            newX := g_WindowResizeInfo.startWinX + deltaX / 2
            newY := g_WindowResizeInfo.startWinY + deltaY / 2
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
    }
    if (newWidth < 100) {
        newWidth := 100
    }
    if (newHeight < 100) {
        newHeight := 100
    }
    if (newX < workArea.left) {
        newX := workArea.left
        if (g_WindowResizeInfo.resizeEdge = "left" || g_WindowResizeInfo.resizeEdge = "top-left" || g_WindowResizeInfo.resizeEdge = "bottom-left") {
            newWidth := g_WindowResizeInfo.startWinW - (currentMouseX - g_WindowResizeInfo.startMouseX)
            if (newWidth < 100) {
                newWidth := 100
            }
        }
    }
    if (newY < workArea.top) {
        newY := workArea.top
        if (g_WindowResizeInfo.resizeEdge = "top" || g_WindowResizeInfo.resizeEdge = "top-left" || g_WindowResizeInfo.resizeEdge = "top-right") {
            newHeight := g_WindowResizeInfo.startWinH - (currentMouseY - g_WindowResizeInfo.startMouseY)
            if (newHeight < 100) {
                newHeight := 100
            }
        }
    }
    if (newX + newWidth > workArea.right) {
        newX := workArea.right - newWidth
        if (newX < workArea.left) {
            newX := workArea.left
            newWidth := workArea.right - workArea.left
        }
    }
    if (newY + newHeight > workArea.bottom) {
        newY := workArea.bottom - newHeight
        if (newY < workArea.top) {
            newY := workArea.top
            newHeight := workArea.bottom - workArea.top
        }
    }
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeInfo.win
}

ProcessWindowMovement2() {
    global g_WindowMoveInfo, g_CurrentMode
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessWindowMovement2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveInfo.startMouseX
    deltaY := currentMouseY - g_WindowMoveInfo.startMouseY
    newX := g_WindowMoveInfo.startWinX + deltaX
    newY := g_WindowMoveInfo.startWinY + deltaY
    workArea := GetScreenWorkArea(g_WindowMoveInfo.win)
    WinGetPos , , &winWidth, &winHeight, g_WindowMoveInfo.win
    if (winWidth > workArea.right - workArea.left || winHeight > workArea.bottom - workArea.top) {
        originalAspectRatio := winWidth / winHeight
        maxWidth := workArea.right - workArea.left
        maxHeight := workArea.bottom - workArea.top
        if (maxWidth / maxHeight > originalAspectRatio) {
            newHeight := maxHeight
            newWidth := Round(newHeight * originalAspectRatio)
        } else {
            newWidth := maxWidth
            newHeight := Round(newWidth / originalAspectRatio)
        }
        if (newWidth < 100)
            newWidth := 100
        if (newHeight < 100)
            newHeight := 100
        winWidth := newWidth
        winHeight := newHeight
        if (newX < workArea.left)
            newX := workArea.left
        if (newY < workArea.top)
            newY := workArea.top
        if (newX + winWidth > workArea.right)
            newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom)
            newY := workArea.bottom - winHeight
        WinMove newX, newY, winWidth, winHeight, g_WindowMoveInfo.win
    } else {
        if (newX < workArea.left)
            newX := workArea.left
        if (newY < workArea.top)
            newY := workArea.top
        if (newX + winWidth > workArea.right)
            newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom)
            newY := workArea.bottom - winHeight
        WinMove newX, newY, , , g_WindowMoveInfo.win
    }
    g_WindowMoveInfo.startMouseX := currentMouseX
    g_WindowMoveInfo.startMouseY := currentMouseY
    g_WindowMoveInfo.startWinX := newX
    g_WindowMoveInfo.startWinY := newY
}

#HotIf g_CurrentMode = "window_control2"

LButton:: {
    global g_WindowMoveInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMoveInfo.startMouseX := startMouseX
        g_WindowMoveInfo.startMouseY := startMouseY
        g_WindowMoveInfo.startWinX := startWinX
        g_WindowMoveInfo.startWinY := startWinY
        g_WindowMoveInfo.win := windowUnderCursor
        SetTimer ProcessWindowMovement2, 10
    }
}

LButton Up:: {
    SetTimer ProcessWindowMovement2, 0
}

MButton:: {
    global g_WindowResizeInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, &startWinW, &startWinH, windowUnderCursor
        cursorXRelative := startMouseX - startWinX
        cursorYRelative := startMouseY - startWinY
        if (cursorXRelative < startWinW / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeInfo.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeInfo.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom"
            } else {
                g_WindowResizeInfo.resizeEdge := "center"
            }
        }
        g_WindowResizeInfo.startMouseX := startMouseX
        g_WindowResizeInfo.startMouseY := startMouseY
        g_WindowResizeInfo.startWinX := startWinX
        g_WindowResizeInfo.startWinY := startWinY
        g_WindowResizeInfo.startWinW := startWinW
        g_WindowResizeInfo.startWinH := startWinH
        g_WindowResizeInfo.win := windowUnderCursor
        SetTimer ProcessWindowResizing2, 10
    }
}

MButton Up:: {
    SetTimer ProcessWindowResizing2, 0
}

WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        currentTransparency := WinGetTransparent(windowUnderCursor)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency - 15
        if (newTransparency < 30)
            newTransparency := 30
        WinSetTransparent newTransparency, windowUnderCursor
        ShowTimedTooltip("透明度: " newTransparency)
    }
}

WheelUp:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        currentTransparency := WinGetTransparent(windowUnderCursor)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency + 15
        if (newTransparency > 255)
            newTransparency := 255
        WinSetTransparent newTransparency, windowUnderCursor
        ShowTimedTooltip("透明度: " newTransparency)
    }
}

#HotIf
