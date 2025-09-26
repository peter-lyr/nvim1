#Requires AutoHotkey v2.0

global g_WindowList := []
global g_CurrentIndex := 0
global g_LastMousePos := {x: 0, y: 0}

WheelUp:: {
    SwitchWindow(-1)
}

WheelDown:: {
    SwitchWindow(1)
}

SwitchWindow(direction) {
    global g_WindowList, g_CurrentIndex, g_LastMousePos
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    if (Abs(mouseX - g_LastMousePos.x) > 10 || Abs(mouseY - g_LastMousePos.y) > 10) {
        g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
        g_CurrentIndex := 0
        g_LastMousePos := {x: mouseX, y: mouseY}
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
        WinActivate("ahk_id " hwnd)
        ShowToolTip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd))
    }
}

GetWindowsAtMousePos(mouseX, mouseY) {
    windows := []
    topWindow := DllCall("WindowFromPoint", "int64", (mouseY << 32) | (mouseX & 0xFFFFFFFF), "ptr")
    allWindows := WinGetList()
    for hwnd in allWindows {
        if (IsDesktopOrTaskbar(hwnd))
            continue
        if (!IsWindowValid(hwnd))
            continue
        if (IsPointInWindow(hwnd, mouseX, mouseY)) {
            windows.Push(hwnd)
        }
    }
    windows := SortWindowsByZOrder(windows)
    return windows
}

IsWindowValid(hwnd) {
    if (!WinExist("ahk_id " hwnd))
        return false
    style := WinGetStyle("ahk_id " hwnd)
    if (!(style & 0x10000000))
        return false
    minMax := WinGetMinMax("ahk_id " hwnd)
    if (minMax = -1)
        return false
    title := WinGetTitle("ahk_id " hwnd)
    if (title = "")
        return false
    return true
}

IsPointInWindow(hwnd, x, y) {
    try {
        WinGetPos(&winX, &winY, &winWidth, &winHeight, "ahk_id " hwnd)
        if (x >= winX && x <= winX + winWidth && y >= winY && y <= winY + winHeight) {
            return true
        }
    }
    return false
}

IsDesktopOrTaskbar(hwnd) {
    class := WinGetClass("ahk_id " hwnd)
    desktopClasses := ["Progman", "WorkerW", "Windows.UI.Core.CoreWindow"]
    taskbarClasses := ["Shell_TrayWnd", "Shell_SecondaryTrayWnd", "NotifyIconOverflowWindow"]
    for _, desktopClass in desktopClasses {
        if (class = desktopClass)
            return true
    }
    for _, taskbarClass in taskbarClasses {
        if (class = taskbarClass)
            return true
    }
    title := WinGetTitle("ahk_id " hwnd)
    if (title = "Program Manager")
        return true
    return false
}

IsToolWindow(hwnd) {
    exStyle := WinGetExStyle("ahk_id " hwnd)
    return (exStyle & 0x80)
}

SortWindowsByZOrder(windows) {
    if (windows.Length <= 1)
        return windows
    sorted := []
    allWindows := WinGetList()
    for hwnd in allWindows {
        if (HasValue(windows, hwnd)) {
            sorted.Push(hwnd)
        }
    }
    return sorted
}

HasValue(arr, value) {
    for item in arr {
        if (item = value)
            return true
    }
    return false
}

ShowToolTip(text) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -1500)
}

^D:: {
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

^R:: {
    global g_WindowList, g_CurrentIndex, g_LastMousePos
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
    g_CurrentIndex := 0
    g_LastMousePos := {x: mouseX, y: mouseY}
    if (g_WindowList.Length > 0) {
        ShowToolTip("重新扫描完成，找到 " g_WindowList.Length " 个窗口")
    } else {
        ShowToolTip("重新扫描完成，未找到窗口")
    }
}

^L:: {
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
