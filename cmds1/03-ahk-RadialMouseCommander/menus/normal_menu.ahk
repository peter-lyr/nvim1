#Requires AutoHotkey v2.0

g_MenuMode := false
g_LastAltPress := 0
g_DoubleClickTime := 300
g_MenuTimer := 0
g_Timeout := 8000

HotkeyMap := Map(
    "a", ["打开记事本", Run.Bind("notepad.exe")],
    "b", ["打开计算器", Run.Bind("calc.exe")],
    "c", ["打开画图", Run.Bind("mspaint.exe")],
)

~LAlt:: {
    global g_MenuMode, g_LastAltPress, g_DoubleClickTime
    currentTime := A_TickCount
    if (currentTime - g_LastAltPress < g_DoubleClickTime) {
        EnterMenuMode()
    }
    g_LastAltPress := currentTime
}

EnterMenuMode() {
    global g_MenuMode, HotkeyMap, g_MenuTimer, g_Timeout
    if (g_MenuMode) {
        return
    }
    g_MenuMode := true
    ShowMenuTooltip(HotkeyMap)
    for key, value in HotkeyMap {
        Hotkey("" key, HandleMenuHotkey.Bind(key), "On")
    }
    Hotkey("Escape", ExitMenuMode, "On")
    g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
}

ExitMenuMode(*) {
    global g_MenuMode, HotkeyMap, g_MenuTimer
    if (!g_MenuMode) {
        return
    }
    g_MenuMode := false
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    for key in HotkeyMap {
        Hotkey("" key, "Off")
    }
    ToolTip()
    Hotkey("Escape", "Off")
}

ShowMenuTooltip(hotkeyMap) {
    global g_Timeout
    tooltipText := "菜单模式（" . g_Timeout//1000 . "秒后自动退出，按ESC立即退出）`n"
    for key, value in hotkeyMap {
        tooltipText .= "[" key "] " value[1] "`n"
    }
    ToolTip(tooltipText)
}

HandleMenuHotkey(key, *) {
    global HotkeyMap
    if (HotkeyMap.Has(key)) {
        HotkeyMap[key][2].Call()
        ExitMenuMode()
    }
}

OnExit((*) => ExitMenuMode())
