#Requires AutoHotkey v2.0
DetectHiddenWindows True

global g_RadialMenuGui := ""
global g_RadialMenuGuiHwnd := 0
global g_RadialMenuRadius := 50
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_TargetWindowHwnd := 0
global g_TargetClickPosX := 0
global g_TargetClickPosY := 0

global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1

global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

global g_CurrentMode := "normal"
global g_PreviousTooltip := ""

global g_DirectionSymbols := Map(
    "R", "→",
    "RD", "↘",
    "D", "↓",
    "LD", "↙",
    "L", "←",
    "LU", "↖",
    "U", "↑",
    "RU", "↗"
)

global g_DirectionNames := Map(
    "R", "右",
    "RD", "右下",
    "D", "下",
    "LD", "左下",
    "L", "左",
    "LU", "左上",
    "U", "上",
    "RU", "右上"
)

global g_ModeActionMappings := Map()

InitializeNormalModeActions() {
    global g_ModeActionMappings
    normalModeActions := Map()
    normalModeActions["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    normalModeActions["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeActions["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeActions["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    normalModeActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    normalModeActions["000LU"] := ["窗口控制模式", EnterWindowControlMode]
    normalModeActions["100LU"] := ["窗口控制模式2", EnterWindowControlMode2]
    g_ModeActionMappings["normal"] := normalModeActions
}

g_WindowsNoControl := [
    "ahk_class tooltips_class32",
]

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

EnterWindowControlMode() {
    global g_CurrentMode := "window_control"
    global g_ModeActionMappings
    windowControlActions := Map()
    windowControlActions["000U"] := ["切换窗口置顶", ToggleTargetWindowTopmost]
    windowControlActions["000D"] := ["激活窗口", ActivateTargetWindow]
    windowControlActions["000L"] := ["恢复普通模式", EnterNormalMode]
    windowControlActions["000R"] := ["单击目标", ClickAtTargetPosition]
    windowControlActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    windowControlActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    windowControlActions["000LD"] := ["按退出键", Send.Bind("{Esc}")]
    windowControlActions["000LU"] := ["窗口控制模式2", EnterWindowControlMode2]
    g_ModeActionMappings["window_control"] := windowControlActions
    ShowTimedTooltip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度")
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复原始热键模式")
}

ToggleTargetWindowTopmost() {
    global g_TargetWindowHwnd
    if (g_TargetWindowHwnd) {
        currentStyle := WinGetExStyle(g_TargetWindowHwnd)
        isTopmost := (currentStyle & 0x8)
        if (isTopmost) {
            WinSetAlwaysOnTop false, g_TargetWindowHwnd
            ShowTimedTooltip("取消窗口置顶")
        } else {
            WinSetAlwaysOnTop true, g_TargetWindowHwnd
            ShowTimedTooltip("窗口已置顶")
        }
    } else {
        ShowTimedTooltip("没有找到目标窗口")
    }
}

ClickAtTargetPosition() {
    global g_TargetClickPosX, g_TargetClickPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickPosX, g_TargetClickPosY, "Left")
    MouseMove(originalX, originalY, 0)
}

#HotIf g_CurrentMode = "window_control"

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

EnterWindowControlMode2() {
    global g_CurrentMode := "window_control2"
    windowControl2Actions := Map()
    windowControl2Actions["000U"] := ["切换窗口置顶", ToggleTargetWindowTopmost]
    windowControl2Actions["000D"] := ["激活窗口", ActivateTargetWindow]
    windowControl2Actions["000L"] := ["恢复普通模式", EnterNormalMode]
    windowControl2Actions["000R"] := ["单击目标", ClickAtTargetPosition]
    windowControl2Actions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    windowControl2Actions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    windowControl2Actions["000LD"] := ["按退出键", Send.Bind("{Esc}")]
    windowControl2Actions["000LU"] := ["窗口控制模式", EnterWindowControlMode]
    g_ModeActionMappings["window_control2"] := windowControl2Actions
    ShowTimedTooltip("已切换到窗口控制模式2`n左键:移动窗口(限制在屏幕内) 中键:调整大小 滚轮:透明度")
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

CreateRadialMenuGui(centerX, centerY, width, height, transparency, backgroundColor) {
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数（当前宽：" width "，高：" height "）")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间（当前值：" transparency "）")
    positionX := centerX - width / 2
    positionY := centerY - height / 2
    radialMenuGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    radialMenuGui.BackColor := backgroundColor
    radialMenuGui.Show("x" positionX " y" positionY " w" width " h" height " NoActivate")
    WinSetTransparent(transparency, radialMenuGui.Hwnd)
    ellipticalRegion := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0,
        "Int", 0,
        "Int", width,
        "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", radialMenuGui.Hwnd, "Ptr", ellipticalRegion, "Int", 1)
    return radialMenuGui
}

DisplayRadialMenuAtCursor() {
    global g_RadialMenuGui, g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    g_RadialMenuCenterX := cursorX
    g_RadialMenuCenterY := cursorY
    menuDiameter := g_RadialMenuRadius * 2
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        menuX := cursorX - g_RadialMenuRadius
        menuY := cursorY - g_RadialMenuRadius
        g_RadialMenuGui.Show("x" menuX " y" menuY " w" menuDiameter " h" menuDiameter " NoActivate")
        g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
    } else {
        try {
            g_RadialMenuGui := CreateRadialMenuGui(cursorX, cursorY, menuDiameter, menuDiameter, 180, "FF0000")
            g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
        }
        catch as e {
            ShowTimedTooltip("创建圆形菜单失败: " . e.Message)
            g_RadialMenuGui := ""
            g_RadialMenuGuiHwnd := 0
        }
    }
}

HideRadialMenu() {
    global g_RadialMenuGui
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        g_RadialMenuGui.Hide()
    }
}

IsCursorInsideRadialMenu() {
    global g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    if (!g_RadialMenuGuiHwnd)
        return false
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    distanceFromCenter := Sqrt((cursorX - g_RadialMenuCenterX)**2 + (cursorY - g_RadialMenuCenterY)**2)
    return distanceFromCenter <= g_RadialMenuRadius
}

CalculateCursorDirection() {
    global g_RadialMenuCenterX, g_RadialMenuCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    deltaX := cursorX - g_RadialMenuCenterX
    deltaY := cursorY - g_RadialMenuCenterY
    angleDegrees := DllCall("msvcrt.dll\atan2", "Double", deltaY, "Double", deltaX, "Double") * 57.29577951308232
    if (angleDegrees < 0)
        angleDegrees += 360
    if (angleDegrees >= 337.5 || angleDegrees < 22.5)
        return "R"
    else if (angleDegrees >= 22.5 && angleDegrees < 67.5)
        return "RD"
    else if (angleDegrees >= 67.5 && angleDegrees < 112.5)
        return "D"
    else if (angleDegrees >= 112.5 && angleDegrees < 157.5)
        return "LD"
    else if (angleDegrees >= 157.5 && angleDegrees < 202.5)
        return "L"
    else if (angleDegrees >= 202.5 && angleDegrees < 247.5)
        return "LU"
    else if (angleDegrees >= 247.5 && angleDegrees < 292.5)
        return "U"
    else if (angleDegrees >= 292.5 && angleDegrees < 337.5)
        return "RU"
}

GetDirectionChineseName(directionCode) {
    global g_DirectionNames
    return g_DirectionNames.Has(directionCode) ? g_DirectionNames[directionCode] : directionCode
}

GetDirectionSymbol(directionCode) {
    global g_DirectionSymbols
    return g_DirectionSymbols.Has(directionCode) ? g_DirectionSymbols[directionCode] : "•"
}

GetCurrentButtonStateAndDirection() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    direction := CalculateCursorDirection()
    return g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" direction
}

GetCurrentModeActionMap() {
    global g_ModeActionMappings, g_CurrentMode
    if (!g_ModeActionMappings.Has(g_CurrentMode)) {
        return g_ModeActionMappings["normal"]
    }
    return g_ModeActionMappings[g_CurrentMode]
}

GenerateRadialMenuDisplay() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    actionMap := GetCurrentModeActionMap()
    directionLayout := [
        ["", "U", ""],
        ["LU", "", "RU"],
        ["L", "", "R"],
        ["LD", "", "RD"],
        ["", "D", ""]
    ]
    displayGrid := []
    for row in directionLayout {
        newRow := []
        for directionCode in row {
            if (directionCode = "") {
                newRow.Push("")
                continue
            }
            stateKey := g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" directionCode
            actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
            actionDescription := actionInfo[1]
            directionSymbol := GetDirectionSymbol(directionCode)
            directionName := GetDirectionChineseName(directionCode)
            displayText := directionSymbol " " directionName ":" actionDescription
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }
    displayText := "模式: " g_CurrentMode " 状态: 左键=" g_LeftButtonState ", 中键=" g_MiddleButtonState ", 滚轮=" g_WheelButtonState "`n`n"
    for row in displayGrid {
        line := ""
        for column in row {
            if (column = "") {
                line .= "        "
            } else {
                targetWidth := 20
                currentWidth := StrLen(column)
                if (currentWidth >= targetWidth) {
                    line .= column
                } else {
                    spacesNeeded := targetWidth - currentWidth
                    leftSpaces := spacesNeeded // 2
                    rightSpaces := spacesNeeded - leftSpaces
                    Loop leftSpaces {
                        line .= " "
                    }
                    line .= column
                    Loop rightSpaces {
                        line .= " "
                    }
                }
            }
        }
        displayText .= line "`n"
    }
    return displayText
}

GenerateCurrentDirectionInfo() {
    directionCode := CalculateCursorDirection()
    directionSymbol := GetDirectionSymbol(directionCode)
    directionName := GetDirectionChineseName(directionCode)
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
    actionDescription := actionInfo[1]
    return "模式: " g_CurrentMode " 方向: " directionSymbol " " directionName "`n操作: " actionDescription
}

UpdateRadialMenuTooltip() {
    global g_PreviousTooltip
    if (IsCursorInsideRadialMenu()) {
        newContent := GenerateRadialMenuDisplay()
    } else {
        newContent := GenerateCurrentDirectionInfo()
    }
    if (newContent != g_PreviousTooltip) {
        ToolTip(newContent)
        g_PreviousTooltip := newContent
    }
}

InitRadialMenuTooltip() {
    global g_PreviousTooltip := ""
    SetTimer(UpdateRadialMenuTooltip, 10)
}

ExitRadialMenuTooltip() {
    ToolTip()
    SetTimer(UpdateRadialMenuTooltip, 0)
    global g_PreviousTooltip := ""
}

CycleLeftButtonState() {
    global g_LeftButtonState, g_MaxLeftButtonStates
    g_LeftButtonState := Mod(g_LeftButtonState + 1, g_MaxLeftButtonStates + 1)
}

CycleMiddleButtonState() {
    global g_MiddleButtonState, g_MaxMiddleButtonStates
    g_MiddleButtonState := Mod(g_MiddleButtonState + 1, g_MaxMiddleButtonStates + 1)
}

CycleWheelButtonState() {
    global g_WheelButtonState, g_MaxWheelButtonStates
    g_WheelButtonState := Mod(g_WheelButtonState + 1, g_MaxWheelButtonStates + 1)
}

ResetButtonStates() {
    global g_LeftButtonState := 0
    global g_MiddleButtonState := 0
    global g_WheelButtonState := 0
}

ShowTimedTooltip(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -2000)
}

CaptureWindowUnderCursor() {
    global g_TargetClickPosX, g_TargetClickPosY, g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(&g_TargetClickPosX, &g_TargetClickPosY, &g_TargetWindowHwnd)
}

ExecuteSelectedAction() {
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    if (actionMap.Has(stateKey)) {
        actionInfo := actionMap[stateKey]
        actionFunction := actionInfo[2]
        try {
            actionFunction()
        } catch as e {
            ShowTimedTooltip("执行操作时出错: " e.Message " [" actionInfo[1] "]")
        }
    } else {
        ShowTimedTooltip("未定义的操作: " stateKey)
    }
}

RButtonDo() {
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    InitRadialMenuTooltip()
}

#HotIf g_CurrentMode = "normal"

~LButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
}

~MButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
}
#HotIf

^!t:: {
    Global g_CurrentMode
    if (g_CurrentMode = "null") {
        g_CurrentMode := "normal"
    } else {
        g_CurrentMode := "null"
    }
    ShowTimedTooltip("g_CurrentMode: " g_CurrentMode)
}

#HotIf g_CurrentMode != "null"

RButton:: {
    ResetButtonStates()
    RButtonDo()
}

~LButton & RButton:: {
    Global g_LeftButtonState := 1
    RButtonDo()
}

RButton Up:: {
    ExitRadialMenuTooltip()
    HideRadialMenu()
    if (IsCursorInsideRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedAction()
    }
    ResetButtonStates()
}

#HotIf

InitializeNormalModeActions()
DisplayRadialMenuAtCursor()
HideRadialMenu()

^Ins::ExitApp
