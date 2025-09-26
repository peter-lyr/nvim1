#Requires AutoHotkey v2.0

global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

;;桌面不透明化
g_WindowsNoTransparencyControl := [
    "ahk_class tooltips_class32",
    GetDesktopClass(),
]

GetDesktopClass() {
    Loop {
        hwnd := WinExist("ahk_class WorkerW")
        if !hwnd
            break
        if ControlGetHwnd("SHELLDLL_DefView1", hwnd) {
            return "ahk_class WorkerW"
        }
    }
    if WinExist("ahk_class Progman")
        return "ahk_class Progman"
    return 0
}

ActivateTargetWindow() {
    global g_TargetWindowHwnd
    WinActivate(g_TargetWindowHwnd)
}

ToggleTargetWindowTopmost(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if (hwnd) {
        currentStyle := WinGetExStyle(hwnd)
        isTopmost := (currentStyle & 0x8)
        if (isTopmost) {
            WinSetAlwaysOnTop false, hwnd
            ShowTimedTooltip("取消窗口置顶")
        } else {
            WinSetAlwaysOnTop true, hwnd
            ShowTimedTooltip("窗口已置顶")
        }
    } else {
        ShowTimedTooltip("没有找到目标窗口")
    }
}

MinimizeTargetWindow(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    WinMinimize(hwnd)
}

ToggleTargetWindowMaximize(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if (WinGetMinMax(hwnd) = 1) {
        WinRestore(hwnd)
    } else {
        WinMaximize(hwnd)
    }
}

ClickAtTargetPosition() {
    global g_TargetClickPosX, g_TargetClickPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickPosX, g_TargetClickPosY, "Left")
    MouseMove(originalX, originalY, 0)
}

TransparencyDown(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    for _, winTitle in g_WindowsNoTransparencyControl {
        if hwnd = WinExist(winTitle) {
            return
        }
    }
    currentTransparency := WinGetTransparent(hwnd)
    if (currentTransparency = "")
        currentTransparency := 255
    newTransparency := currentTransparency - 15
    if (newTransparency < 30)
        newTransparency := 30
    WinSetTransparent newTransparency, hwnd
    ShowTimedTooltip("透明度: " newTransparency)
}

TransparencyUp(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    for _, winTitle in g_WindowsNoTransparencyControl {
        if hwnd = WinExist(winTitle) {
            return
        }
    }
    currentTransparency := WinGetTransparent(hwnd)
    if (currentTransparency = "")
        currentTransparency := 255
    newTransparency := currentTransparency + 15
    if (newTransparency > 255)
        newTransparency := 255
    WinSetTransparent newTransparency, hwnd
    ShowTimedTooltip("透明度: " newTransparency)
}
