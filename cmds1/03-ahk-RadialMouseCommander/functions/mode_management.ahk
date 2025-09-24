; 模式管理相关函数

#Requires AutoHotkey v2.0

; 模式管理
global g_CurrentMode := "normal"

InitializeModeActionMappings() {
    InitializeNormalModeActions()
    InitializeWindowControlModeActions()
}

EnterWindowControlMode() {
    global g_CurrentMode := "window_control"
    ShowTimedTooltip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度")
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复原始热键模式")
}
