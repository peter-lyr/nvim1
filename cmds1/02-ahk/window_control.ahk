#Requires AutoHotkey v2.0

global g_ResizeData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0, initWinW: 0, initWinH: 0, direction: ""}
global g_MoveData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0}

WindowControlMode() {
    global g_CurrentMode := "window_control"
    ToolTip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度 右键:恢复")
    SetTimer(() => ToolTip(), -2000)
}

#HotIf g_CurrentMode = "window_control"

RButton::
{
    MouseGetPos , , &MouseWin
    WinActivate(MouseWin)
}

RButton & LButton::
{
    Click "Left"
}

RButton & MButton::
{
    global g_CurrentMode := "normal"
    ToolTip("已恢复原始热键模式")
    SetTimer(() => ToolTip(), -2000)
}

LButton::
{
    global g_MoveData
    MouseGetPos , , &MouseWin
    if MouseWin {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, , , MouseWin
        g_MoveData.initMouseX := initMouseX
        g_MoveData.initMouseY := initMouseY
        g_MoveData.initWinX := initWinX
        g_MoveData.initWinY := initWinY
        g_MoveData.win := MouseWin
        SetTimer MoveWindow, 10
    }
}

MoveWindow() {
    global g_MoveData
    if !GetKeyState("LButton", "P") {
        SetTimer MoveWindow, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_MoveData.initMouseX
    deltaY := currentMouseY - g_MoveData.initMouseY
    newX := g_MoveData.initWinX + deltaX
    newY := g_MoveData.initWinY + deltaY
    WinMove newX, newY, , , g_MoveData.win
}

LButton Up::
{
    SetTimer MoveWindow, 0
}

MButton::
{
    global g_ResizeData
    MouseGetPos , , &MouseWin
    if MouseWin {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, &initWinW, &initWinH, MouseWin
        relX := initMouseX - initWinX
        relY := initMouseY - initWinY
        if (relX < initWinW / 3) {
            if (relY < initWinH / 3) {
                g_ResizeData.direction := "top-left"
            } else if (relY > initWinH * 2 / 3) {
                g_ResizeData.direction := "bottom-left"
            } else {
                g_ResizeData.direction := "left"
            }
        } else if (relX > initWinW * 2 / 3) {
            if (relY < initWinH / 3) {
                g_ResizeData.direction := "top-right"
            } else if (relY > initWinH * 2 / 3) {
                g_ResizeData.direction := "bottom-right"
            } else {
                g_ResizeData.direction := "right"
            }
        } else {
            if (relY < initWinH / 3) {
                g_ResizeData.direction := "top"
            } else if (relY > initWinH * 2 / 3) {
                g_ResizeData.direction := "bottom"
            } else {
                g_ResizeData.direction := "center"
            }
        }
        g_ResizeData.initMouseX := initMouseX
        g_ResizeData.initMouseY := initMouseY
        g_ResizeData.initWinX := initWinX
        g_ResizeData.initWinY := initWinY
        g_ResizeData.initWinW := initWinW
        g_ResizeData.initWinH := initWinH
        g_ResizeData.win := MouseWin
        SetTimer ResizeWindow, 10
    }
}

ResizeWindow() {
    global g_ResizeData
    if !GetKeyState("MButton", "P") {
        SetTimer ResizeWindow, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_ResizeData.initMouseX
    deltaY := currentMouseY - g_ResizeData.initMouseY
    newX := g_ResizeData.initWinX
    newY := g_ResizeData.initWinY
    newWidth := g_ResizeData.initWinW
    newHeight := g_ResizeData.initWinH
    switch g_ResizeData.direction {
        case "top-left":
            newX := g_ResizeData.initWinX + deltaX
            newY := g_ResizeData.initWinY + deltaY
            newWidth := g_ResizeData.initWinW - deltaX
            newHeight := g_ResizeData.initWinH - deltaY
        case "top":
            newY := g_ResizeData.initWinY + deltaY
            newHeight := g_ResizeData.initWinH - deltaY
        case "top-right":
            newY := g_ResizeData.initWinY + deltaY
            newWidth := g_ResizeData.initWinW + deltaX
            newHeight := g_ResizeData.initWinH - deltaY
        case "left":
            newX := g_ResizeData.initWinX + deltaX
            newWidth := g_ResizeData.initWinW - deltaX
        case "right":
            newWidth := g_ResizeData.initWinW + deltaX
        case "bottom-left":
            newX := g_ResizeData.initWinX + deltaX
            newWidth := g_ResizeData.initWinW - deltaX
            newHeight := g_ResizeData.initWinH + deltaY
        case "bottom":
            newHeight := g_ResizeData.initWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_ResizeData.initWinW + deltaX
            newHeight := g_ResizeData.initWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_ResizeData.win
}

MButton Up::
{
    SetTimer ResizeWindow, 0
}

WheelDown::
{
    MouseGetPos , , &MouseWin
    if MouseWin {
        currentTrans := WinGetTransparent(MouseWin)
        if (currentTrans = "")
            currentTrans := 255
        newTrans := currentTrans - 15
        if (newTrans < 30)
            newTrans := 30
        WinSetTransparent newTrans, MouseWin
        ToolTip("透明度: " newTrans)
        SetTimer(() => ToolTip(), -1000)
    }
}

WheelUp::
{
    MouseGetPos , , &MouseWin
    if MouseWin {
        currentTrans := WinGetTransparent(MouseWin)
        if (currentTrans = "")
            currentTrans := 255
        newTrans := currentTrans + 15
        if (newTrans > 255)
            newTrans := 255
        WinSetTransparent newTrans, MouseWin
        ToolTip("透明度: " newTrans)
        SetTimer(() => ToolTip(), -1000)
    }
}

#HotIf
