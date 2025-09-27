#Requires AutoHotkey v2.0

g_WindowsNoControl := [
    "ahk_class tooltips_class32",
]

EnterWindowControlMode() {
    ModeActionsSet("window_control",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
    )
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

#HotIf g_CurrentMode = "window_control"

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
        SetTimer ProcessWindowMovement, 10
    }
}

LButton Up:: {
    SetTimer ProcessWindowMovement, 0
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
        SetTimer ProcessWindowResizing, 10
    }
}

MButton Up:: {
    SetTimer ProcessWindowResizing, 0
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
    TransparencyDown(windowUnderCursor)
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
    TransparencyUp(windowUnderCursor)
}

#HotIf
