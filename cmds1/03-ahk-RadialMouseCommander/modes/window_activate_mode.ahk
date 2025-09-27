#Requires AutoHotkey v2.0

;;优化GetWindowsAtMousePos性能
;;彻底修复切换激活窗口导致任务栏图标闪烁的问题
;;避免误置顶窗口
;;已适配模式

global g_WindowList := []
global g_CurrentIndex := 0
global g_LastMousePos := {x: 0, y: 0}
global g_LastActiveHwnd := 0

EnterWindowActivateMode() {
    global g_CurrentMode := "window_activate"
    global g_ModeActionMappings
    actionsMap := Map()
    actionsMap["000U"] := ["切换窗口置顶", ToggleTargetWindowTopmost]
    actionsMap["000D"] := ["激活窗口", ActivateTargetWindow]
    actionsMap["000L"] := ["恢复普通模式", EnterNormalMode]
    actionsMap["000R"] := ["单击目标", ClickAtTargetPosition]
    actionsMap["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    actionsMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    actionsMap["000LD"] := ["Esc", Send.Bind("{Esc}")]
    actionsMap["000LU"] := ["窗口控制模式2", EnterWindowControlMode2]
    g_ModeActionMappings["window_activate"] := actionsMap
    ShowTimedTooltip("已切换到窗口激活模式`n左键:移动窗口 中键:调整大小 滚轮:透明度")
}

SwitchWindow(direction) {
    global g_WindowList, g_CurrentIndex, g_LastMousePos, g_LastActiveHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    if (Abs(mouseX - g_LastMousePos.x) > 10 || Abs(mouseY - g_LastMousePos.y) > 10) {
        g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
        g_CurrentIndex := 0
        g_LastMousePos := {x: mouseX, y: mouseY}
        g_LastActiveHwnd := 0
        if (g_WindowList.Length > 0) {
            ShowTimedTooltip("找到 " g_WindowList.Length " 个窗口")
        } else {
            ShowTimedTooltip("未找到符合条件的窗口")
        }
    }
    if (g_WindowList.Length = 0)
        return
    if (g_CurrentIndex = 0) {
        g_CurrentIndex := 1
    } else {
        g_CurrentIndex += direction
        if (g_CurrentIndex > g_WindowList.Length)
            g_CurrentIndex := 1
        else if (g_CurrentIndex < 1)
            g_CurrentIndex := g_WindowList.Length
    }
    try {
        hwnd := g_WindowList[g_CurrentIndex]
        if (hwnd = g_LastActiveHwnd) {
            ShowTimedTooltip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd) " (已激活)")
            return
        }
        SwitchToWindow(hwnd)
        g_LastActiveHwnd := hwnd
        ShowTimedTooltip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd))
    }
}

SwitchToWindow(hwnd) {
    if (WinActive("ahk_id " hwnd)) {
        return
    }
    if (WinGetMinMax("ahk_id " hwnd) = -1) {
        WinRestore("ahk_id " hwnd)
    }
    ActivateWindowSafely(hwnd)
}

ActivateWindowSafely(hwnd) {
    SimulateAltTab(hwnd)
    if (!WinActive("ahk_id " hwnd)) {
        try {
            DllCall("SetForegroundWindow", "ptr", hwnd)
        }
    }
}

SimulateAltTab(hwnd) {
    originalHwnd := WinGetID("A")
    if (originalHwnd = hwnd) {
        return
    }
    Send("!{Esc}")
    WinWaitActive("ahk_id " hwnd, , 0.1)
    if (!WinActive("ahk_id " hwnd)) {
        WinActivate("ahk_id " hwnd)
    }
}

GetWindowsAtMousePos(mouseX, mouseY) {
    static lastMousePos := {x: 0, y: 0}
    static lastWindows := []
    static lastTimestamp := 0
    currentTime := A_TickCount
    if (Abs(mouseX - lastMousePos.x) <= 2 && Abs(mouseY - lastMousePos.y) <= 2 && currentTime - lastTimestamp < 500) {
        return lastWindows
    }
    windows := []
    allWindows := WinGetList()
    windows.Capacity := allWindows.Length
    for hwnd in allWindows {
        style := WinGetStyle("ahk_id " hwnd)
        if (!(style & 0x10000000))
            continue
        if (WinGetMinMax("ahk_id " hwnd) = -1)
            continue
        class := WinGetClass("ahk_id " hwnd)
        if (class = "Progman" || class = "WorkerW" || class = "Shell_TrayWnd" ||
            class = "Shell_SecondaryTrayWnd" || class = "NotifyIconOverflowWindow" ||
            class = "Windows.UI.Core.CoreWindow") {
            continue
        }
        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x80)
            continue
        title := WinGetTitle("ahk_id " hwnd)
        if (title = "")
            continue
        if (IsPointInWindowOptimized(hwnd, mouseX, mouseY)) {
            windows.Push(hwnd)
        }
    }
    lastMousePos := {x: mouseX, y: mouseY}
    lastWindows := windows
    lastTimestamp := currentTime
    return windows
}

IsPointInWindowOptimized(hwnd, x, y) {
    rect := Buffer(16, 0)
    if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rect)
        return false
    left := NumGet(rect, 0, "Int")
    top := NumGet(rect, 4, "Int")
    right := NumGet(rect, 8, "Int")
    bottom := NumGet(rect, 12, "Int")
    return (x >= left && x <= right && y >= top && y <= bottom)
}

#HotIf g_CurrentMode = "window_activate"

WheelUp:: {
    SwitchWindow(-1)
}

WheelDown:: {
    SwitchWindow(1)
}

LButton:: {
    EnterNormalMode()
}

^Del:: {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    title := WinGetTitle("ahk_id " mouseWin)
    class := WinGetClass("ahk_id " mouseWin)
    style := WinGetStyle("ahk_id " mouseWin)
    exStyle := WinGetExStyle("ahk_id " mouseWin)
    info := "窗口信息：`n"
    info .= "标题: " title "`n"
    info .= "类名: " class "`n"
    info .= "样式: " Format("0x{:X}", style) "`n"
    info .= "扩展样式: " Format("0x{:X}", exStyle) "`n"
    info .= "鼠标位置: " mouseX ", " mouseY "`n"
    info .= "窗口ID: " mouseWin
    MsgBox(info)
}

^End:: {
    global g_WindowList, g_CurrentIndex, g_LastMousePos, g_LastActiveHwnd
    MouseGetPos(&mouseX, &mouseY)
    g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
    g_CurrentIndex := 0
    g_LastMousePos := {x: mouseX, y: mouseY}
    g_LastActiveHwnd := 0
    if (g_WindowList.Length > 0) {
        ShowTimedTooltip("重新扫描完成，找到 " g_WindowList.Length " 个窗口")
    } else {
        ShowTimedTooltip("重新扫描完成，未找到窗口")
    }
}

^PgDn:: {
    global g_WindowList, g_CurrentIndex
    if (g_WindowList.Length = 0) {
        MsgBox("没有找到窗口")
        return
    }
    listText := "当前窗口列表：`n`n"
    for index, hwnd in g_WindowList {
        title := WinGetTitle("ahk_id " hwnd)
        class := WinGetClass("ahk_id " hwnd)
        status := (index = g_CurrentIndex) ? " ← 当前" : ""
        listText .= index ". " title " (" class ")" status "`n"
    }
    MsgBox(listText)
}

#HotIf
