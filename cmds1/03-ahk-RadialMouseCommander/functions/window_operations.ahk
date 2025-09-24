; 窗口操作相关函数

#Requires AutoHotkey v2.0

; 窗口操作变量
global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

ActivateTargetWindow() {
    global g_TargetWindowHwnd
    WinActivate(g_TargetWindowHwnd)
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
