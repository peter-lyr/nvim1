#Requires AutoHotkey v2.0

;;优化GetWindowsAtMousePos性能
;;彻底修复切换激活窗口导致任务栏图标闪烁的问题
;;有些窗口会被误置顶

global g_WindowList := []
global g_CurrentIndex := 0
global g_LastMousePos := {x: 0, y: 0}
global g_LastActiveHwnd := 0
global g_UnpinTimer := 0

WheelUp:: {
    SwitchWindow(-1)
}

WheelDown:: {
    SwitchWindow(1)
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
            ShowToolTip("找到 " g_WindowList.Length " 个窗口")
        } else {
            ShowToolTip("未找到符合条件的窗口")
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
            ShowToolTip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd) " (已激活)")
            return
        }

        SwitchToWindow(hwnd)
        g_LastActiveHwnd := hwnd
        ShowToolTip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd))
    }
}

SwitchToWindow(hwnd) {
    global g_UnpinTimer

    if (WinGetMinMax("ahk_id " hwnd) = -1) {
        WinRestore("ahk_id " hwnd)
    }

    WinSetAlwaysOnTop(1, "ahk_id " hwnd)

    if (g_UnpinTimer) {
        SetTimer(g_UnpinTimer, 0)
    }

    unpinFunc := UnpinWindow.Bind(hwnd)

    g_UnpinTimer := unpinFunc
    SetTimer(unpinFunc, -50)
}

UnpinWindow(hwnd) {
    WinSetAlwaysOnTop(0, "ahk_id " hwnd)
    global g_UnpinTimer := 0
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

ShowToolTip(text) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -1500)
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
        ShowToolTip("重新扫描完成，找到 " g_WindowList.Length " 个窗口")
    } else {
        ShowToolTip("重新扫描完成，未找到窗口")
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

^Esc::ExitApp
