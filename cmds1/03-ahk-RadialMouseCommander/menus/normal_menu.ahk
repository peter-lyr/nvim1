#Requires AutoHotkey v2.0

; 多个菜单模式
; 双击Alt进入normal菜单，热键为HotkeyMap := Map(
;     "a", ["打开记事本", Run.Bind("notepad.exe")],
;     "b", ["打开计算器", Run.Bind("calc.exe")],
;     "c", ["打开画图", Run.Bind("mspaint.exe")],
;     "d", ["进入second菜单",  SecondMenu],
; )
; 按热键d进入second菜单，热键为HotkeyMap2 := Map(
;     "a", ["向左", Send.Bind("{Left}")],
;     "d", ["向右", Send.Bind("{Right}")],
;     "s", ["进入normal菜单", NormalMenu],
; )
; 此时按热键s可以从新回到normal菜单，可以实现吗，输出完整的文件

g_MenuMode := false
g_CurrentMenu := "normal"
g_LastAltPress := 0
g_DoubleClickTime := 300
g_MenuTimer := 0
g_Timeout := 8000

NormalHotkeyMap := Map(
    "a", ["打开记事本", Run.Bind("notepad.exe")],
    "b", ["打开计算器", Run.Bind("calc.exe")],
    "c", ["打开画图", Run.Bind("mspaint.exe")],
    "d", ["进入second菜单", SecondMenu]
)

SecondHotkeyMap := Map(
    "a", ["向左", Send.Bind("{Left}")],
    "d", ["向右", Send.Bind("{Right}")],
    "s", ["进入normal菜单", NormalMenu]
)

~LAlt::
{
    global g_MenuMode, g_LastAltPress, g_DoubleClickTime
    currentTime := A_TickCount
    if (currentTime - g_LastAltPress < g_DoubleClickTime && !g_MenuMode) {
        EnterMenuMode("normal")
    }
    g_LastAltPress := currentTime
}

EnterMenuMode(menuType) {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, g_Timeout
    if (g_MenuMode) {
        return
    }
    g_MenuMode := true
    g_CurrentMenu := menuType
    if (menuType = "normal") {
        ShowMenuTooltip(NormalHotkeyMap, "Normal菜单")
    } else if (menuType = "second") {
        ShowMenuTooltip(SecondHotkeyMap, "Second菜单")
    }
    RegisterMenuHotkeys(menuType)
    Hotkey("Escape", ExitMenuMode, "On")
    g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
}

ExitMenuMode(*) {
    global g_MenuMode, g_MenuTimer
    if (!g_MenuMode) {
        return
    }
    g_MenuMode := false
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    UnregisterAllMenuHotkeys()
    ToolTip()
    Hotkey("Escape", "Off")
}

RegisterMenuHotkeys(menuType) {
    if (menuType = "normal") {
        for key, value in NormalHotkeyMap {
            Hotkey(key, HandleMenuHotkey.Bind(key, "normal"), "On")
        }
    } else if (menuType = "second") {
        for key, value in SecondHotkeyMap {
            Hotkey(key, HandleMenuHotkey.Bind(key, "second"), "On")
        }
    }
}

UnregisterAllMenuHotkeys() {
    for key in NormalHotkeyMap {
        try Hotkey(key, "Off")
    }
    for key in SecondHotkeyMap {
        try Hotkey(key, "Off")
    }
}

ShowMenuTooltip(hotkeyMap, menuName) {
    global g_Timeout
    tooltipText := menuName . "（" . g_Timeout//1000 . "秒后自动退出，按ESC立即退出）`n"
    for key, value in hotkeyMap {
        tooltipText .= "[" key "] " value[1] "`n"
    }
    ToolTip(tooltipText)
}

HandleMenuHotkey(key, menuType, *) {
    global g_CurrentMenu
    if (g_CurrentMenu != menuType) {
        return
    }
    if (menuType = "normal" && NormalHotkeyMap.Has(key)) {
        action := NormalHotkeyMap[key][2]
        action.Call()
        if (key != "d") {
            ExitMenuMode()
        }
    }
    else if (menuType = "second" && SecondHotkeyMap.Has(key)) {
        action := SecondHotkeyMap[key][2]
        action.Call()
        if (key != "s") {
            ExitMenuMode()
        }
    }
}

SecondMenu() {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer
    if (!g_MenuMode || g_CurrentMenu != "normal") {
        return
    }
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    g_MenuMode := false
    EnterMenuMode("second")
}

NormalMenu() {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer
    if (!g_MenuMode || g_CurrentMenu != "second") {
        return
    }
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    g_MenuMode := false
    EnterMenuMode("normal")
}

OnExit((*) => ExitMenuMode())

^Ins::ExitApp
