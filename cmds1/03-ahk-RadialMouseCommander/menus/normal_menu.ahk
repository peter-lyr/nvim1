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

; 增加一种功能，有些热键在执行后，继续维持当前菜单，
; 比如进入second菜单后可以一直按a来向左，一直按d来向右

g_MenuMode := false
g_CurrentMenu := "normal"
g_LastAltPress := 0
g_DoubleClickTime := 300
g_MenuTimer := 0
g_Timeout := 8000

; 修改数据结构，增加第三个参数：是否维持菜单
NormalHotkeyMap := Map(
    "a", ["打开记事本", Run.Bind("notepad.exe"), false],  ; 执行后退出菜单
    "b", ["打开计算器", Run.Bind("calc.exe"), false],     ; 执行后退出菜单
    "c", ["打开画图", Run.Bind("mspaint.exe"), false],    ; 执行后退出菜单
    "d", ["进入second菜单", SecondMenu, true]             ; 执行后维持菜单
)

SecondHotkeyMap := Map(
    "a", ["向左", Send.Bind("{Left}"), true],             ; 执行后维持菜单
    "d", ["向右", Send.Bind("{Right}"), true],            ; 执行后维持菜单
    "s", ["进入normal菜单", NormalMenu, true]             ; 执行后维持菜单
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

    ; 显示对应菜单的提示
    if (menuType = "normal") {
        ShowMenuTooltip(NormalHotkeyMap, "Normal菜单")
    } else if (menuType = "second") {
        ShowMenuTooltip(SecondHotkeyMap, "Second菜单")
    }

    RegisterMenuHotkeys(menuType)
    Hotkey("Escape", ExitMenuMode, "On")

    ; 重置超时定时器
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
        tooltipText .= "[" key "] " value[1]
        if (value[3]) {  ; 如果维持菜单，显示提示
            tooltipText .= " (维持菜单)"
        }
        tooltipText .= "`n"
    }
    ToolTip(tooltipText)
}

HandleMenuHotkey(key, menuType, *) {
    global g_CurrentMenu, g_MenuTimer, g_Timeout

    ; 确保处理的是当前菜单的热键
    if (g_CurrentMenu != menuType) {
        return
    }

    if (menuType = "normal" && NormalHotkeyMap.Has(key)) {
        action := NormalHotkeyMap[key][2]
        action.Call()

        ; 根据第三个参数决定是否维持菜单
        if (!NormalHotkeyMap[key][3]) {
            ExitMenuMode()
        } else {
            ; 维持菜单，重置超时定时器
            if (g_MenuTimer) {
                SetTimer(g_MenuTimer, 0)
            }
            g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
        }
    }
    else if (menuType = "second" && SecondHotkeyMap.Has(key)) {
        action := SecondHotkeyMap[key][2]
        action.Call()

        ; 根据第三个参数决定是否维持菜单
        if (!SecondHotkeyMap[key][3]) {
            ExitMenuMode()
        } else {
            ; 维持菜单，重置超时定时器
            if (g_MenuTimer) {
                SetTimer(g_MenuTimer, 0)
            }
            g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
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
