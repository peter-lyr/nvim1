; 工具提示相关函数

#Requires AutoHotkey v2.0

global g_PreviousTooltip := ""
global g_UpdateRadialMenuTooltipEn := 1
global g_ShowTimedTooltipEn := 1

ToggleUpdateRadialMenuTooltipEn() {
    global g_UpdateRadialMenuTooltipEn
    g_UpdateRadialMenuTooltipEn := 1 -g_UpdateRadialMenuTooltipEn
}

ToggleShowTimedTooltipEn() {
    global g_ShowTimedTooltipEn
    g_ShowTimedTooltipEn := 1 -g_ShowTimedTooltipEn
}

ShowTimedTooltip(message) {
    global g_ShowTimedTooltipEn
    if not g_ShowTimedTooltipEn {
        return
    }
    ToolTip(message)
    SetTimer(() => ToolTip(), -2000)
}

UpdateRadialMenuTooltip() {
    global g_PreviousTooltip
    global g_UpdateRadialMenuTooltipEn
    if not g_UpdateRadialMenuTooltipEn {
        return
    }
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
