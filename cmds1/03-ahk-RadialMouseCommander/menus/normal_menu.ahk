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

; NormalMenu和SecondMenu合并成一个函数
; 接收菜单名作为参数，以便我增加third菜单，……等等菜单

g_MenuMode := false
g_CurrentMenu := "normal"
g_LastAltPress := 0
g_DoubleClickTime := 300
g_MenuTimer := 0
g_Timeout := 8000

; 定义所有菜单
MenuDefinitions := Map(
    "normal", Map(
        "a", ["打开记事本", Run.Bind("notepad.exe"), false],
        "b", ["打开计算器", Run.Bind("calc.exe"), false],
        "c", ["打开画图", Run.Bind("mspaint.exe"), false],
        "d", ["进入second菜单", SwitchMenu.Bind("second"), true]
    ),
    "second", Map(
        "a", ["向左", Send.Bind("{Left}"), true],
        "d", ["向右", Send.Bind("{Right}"), true],
        "s", ["进入normal菜单", SwitchMenu.Bind("normal"), true],
        "t", ["进入third菜单", SwitchMenu.Bind("third"), true]
    ),
    "third", Map(
        "a", ["向上", Send.Bind("{Up}"), true],
        "d", ["向下", Send.Bind("{Down}"), true],
        "s", ["进入second菜单", SwitchMenu.Bind("second"), true],
        "n", ["进入normal菜单", SwitchMenu.Bind("normal"), true]
    )
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
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, g_Timeout, MenuDefinitions

    if (g_MenuMode) {
        return
    }

    g_MenuMode := true
    g_CurrentMenu := menuType

    ; 显示对应菜单的提示
    if (MenuDefinitions.Has(menuType)) {
        ShowMenuTooltip(MenuDefinitions[menuType], menuType . "菜单")
    } else {
        ShowMenuTooltip(Map(), "未知菜单")
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
    global MenuDefinitions

    if (MenuDefinitions.Has(menuType)) {
        for key, value in MenuDefinitions[menuType] {
            Hotkey(key, HandleMenuHotkey.Bind(key, menuType), "On")
        }
    }
}

UnregisterAllMenuHotkeys() {
    global MenuDefinitions

    for menuName, hotkeyMap in MenuDefinitions {
        for key in hotkeyMap {
            try Hotkey(key, "Off")
        }
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
    global g_CurrentMenu, g_MenuTimer, g_Timeout, MenuDefinitions

    ; 确保处理的是当前菜单的热键
    if (g_CurrentMenu != menuType) {
        return
    }

    if (MenuDefinitions.Has(menuType) && MenuDefinitions[menuType].Has(key)) {
        action := MenuDefinitions[menuType][key][2]
        action.Call()

        ; 根据第三个参数决定是否维持菜单
        if (!MenuDefinitions[menuType][key][3]) {
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

; 通用的菜单切换函数
SwitchMenu(targetMenu) {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, MenuDefinitions

    if (!g_MenuMode || g_CurrentMenu = targetMenu || !MenuDefinitions.Has(targetMenu)) {
        return
    }

    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }

    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    g_MenuMode := false
    EnterMenuMode(targetMenu)
}

OnExit((*) => ExitMenuMode())

^Ins::ExitApp
