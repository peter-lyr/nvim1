; 窗口控制模式配置

#Requires AutoHotkey v2.0

EnterWindowControlMode() {
    global g_CurrentMode := "window_control"
    global g_ModeActionMappings
    windowControlActions := Map()
    windowControlActions["000L"] := ["恢复普通模式", EnterNormalMode]
    windowControlActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    windowControlActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    windowControlActions["000U"] := ["激活窗口", ActivateTargetWindow]
    windowControlActions["000D"] := ["按退出键", Send.Bind("{Esc}")]
    windowControlActions["000LU"] := ["单击目标", ClickAtTargetPosition]
    windowControlActions["000LD"] := ["单击目标", ClickAtTargetPosition]
    windowControlActions["000R"] := ["单击目标", ClickAtTargetPosition]
    g_ModeActionMappings["window_control"] := windowControlActions
    ShowTimedTooltip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度")
}

#HotIf g_CurrentMode = "window_control"

LButton:: {
    global g_WindowMoveInfo
    MouseGetPos , , &windowUnderCursor
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
    MouseGetPos , , &windowUnderCursor
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
    MouseGetPos , , &windowUnderCursor
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
    MouseGetPos , , &windowUnderCursor
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
