; 工具提示相关函数

global g_PreviousTooltip := ""

ShowTimedTooltip(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -2000)
}

UpdateRadialMenuTooltip() {
    global g_PreviousTooltip
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
