#Requires AutoHotkey v2.0

; 窗口操作变量
global g_WindowResizeData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0, initWinW: 0, initWinH: 0, direction: ""}
global g_WindowMoveData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0}

SwitchToWindowControlMode() {
    global g_CurrentMode := "window_control"
    windowControlMap := Map()
    windowControlMap["000L"] := ["恢复普通模式", SwitchToNormalMode]
    g_ActionFunctionMaps["window_control"] := windowControlMap
    ShowTemporaryTooltip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度 右键:恢复")
}

#HotIf g_CurrentMode = "window_control"

MoveWindowWithMouse() {
    global g_WindowMoveData
    if !GetKeyState("LButton", "P") {
        SetTimer MoveWindowWithMouse, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveData.initMouseX
    deltaY := currentMouseY - g_WindowMoveData.initMouseY
    newX := g_WindowMoveData.initWinX + deltaX
    newY := g_WindowMoveData.initWinY + deltaY
    WinMove newX, newY, , , g_WindowMoveData.win
}

ResizeWindowWithMouse() {
    global g_WindowResizeData
    if !GetKeyState("MButton", "P") {
        SetTimer ResizeWindowWithMouse, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeData.initMouseX
    deltaY := currentMouseY - g_WindowResizeData.initMouseY
    newX := g_WindowResizeData.initWinX
    newY := g_WindowResizeData.initWinY
    newWidth := g_WindowResizeData.initWinW
    newHeight := g_WindowResizeData.initWinH
    switch g_WindowResizeData.direction {
        case "top-left":
            newX := g_WindowResizeData.initWinX + deltaX
            newY := g_WindowResizeData.initWinY + deltaY
            newWidth := g_WindowResizeData.initWinW - deltaX
            newHeight := g_WindowResizeData.initWinH - deltaY
        case "top":
            newY := g_WindowResizeData.initWinY + deltaY
            newHeight := g_WindowResizeData.initWinH - deltaY
        case "top-right":
            newY := g_WindowResizeData.initWinY + deltaY
            newWidth := g_WindowResizeData.initWinW + deltaX
            newHeight := g_WindowResizeData.initWinH - deltaY
        case "left":
            newX := g_WindowResizeData.initWinX + deltaX
            newWidth := g_WindowResizeData.initWinW - deltaX
        case "right":
            newWidth := g_WindowResizeData.initWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeData.initWinX + deltaX
            newWidth := g_WindowResizeData.initWinW - deltaX
            newHeight := g_WindowResizeData.initWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeData.initWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_WindowResizeData.initWinW + deltaX
            newHeight := g_WindowResizeData.initWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeData.win
}

LButton:: {
    global g_WindowMoveData
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, , , mouseWindow
        g_WindowMoveData.initMouseX := initMouseX
        g_WindowMoveData.initMouseY := initMouseY
        g_WindowMoveData.initWinX := initWinX
        g_WindowMoveData.initWinY := initWinY
        g_WindowMoveData.win := mouseWindow
        SetTimer MoveWindowWithMouse, 10
    }
}

LButton Up:: {
    SetTimer MoveWindowWithMouse, 0
}

MButton:: {
    global g_WindowResizeData
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, &initWinW, &initWinH, mouseWindow
        relativeX := initMouseX - initWinX
        relativeY := initMouseY - initWinY
        if (relativeX < initWinW / 3) {
            if (relativeY < initWinH / 3) {
                g_WindowResizeData.direction := "top-left"
            } else if (relativeY > initWinH * 2 / 3) {
                g_WindowResizeData.direction := "bottom-left"
            } else {
                g_WindowResizeData.direction := "left"
            }
        } else if (relativeX > initWinW * 2 / 3) {
            if (relativeY < initWinH / 3) {
                g_WindowResizeData.direction := "top-right"
            } else if (relativeY > initWinH * 2 / 3) {
                g_WindowResizeData.direction := "bottom-right"
            } else {
                g_WindowResizeData.direction := "right"
            }
        } else {
            if (relativeY < initWinH / 3) {
                g_WindowResizeData.direction := "top"
            } else if (relativeY > initWinH * 2 / 3) {
                g_WindowResizeData.direction := "bottom"
            } else {
                g_WindowResizeData.direction := "center"
            }
        }
        g_WindowResizeData.initMouseX := initMouseX
        g_WindowResizeData.initMouseY := initMouseY
        g_WindowResizeData.initWinX := initWinX
        g_WindowResizeData.initWinY := initWinY
        g_WindowResizeData.initWinW := initWinW
        g_WindowResizeData.initWinH := initWinH
        g_WindowResizeData.win := mouseWindow
        SetTimer ResizeWindowWithMouse, 10
    }
}

MButton Up:: {
    SetTimer ResizeWindowWithMouse, 0
}

WheelDown:: {
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        currentTransparency := WinGetTransparent(mouseWindow)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency - 15
        if (newTransparency < 30)
            newTransparency := 30
        WinSetTransparent newTransparency, mouseWindow
        ShowTemporaryTooltip("透明度: " newTransparency)
    }
}

WheelUp:: {
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        currentTransparency := WinGetTransparent(mouseWindow)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency + 15
        if (newTransparency > 255)
            newTransparency := 255
        WinSetTransparent newTransparency, mouseWindow
        ShowTemporaryTooltip("透明度: " newTransparency)
    }
}

#HotIf

