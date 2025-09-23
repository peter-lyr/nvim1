#Requires AutoHotkey v2.0

MinimizeTargetWindow() {
    global g_TargetWindowHwnd
    WinMinimize(g_TargetWindowHwnd)
}

ToggleMaximizeWindow() {
    global g_TargetWindowHwnd
    if (WinGetMinMax(g_TargetWindowHwnd) == 1) {
        WinRestore(g_TargetWindowHwnd)
    } else {
        WinMaximize(g_TargetWindowHwnd)
    }
}

ExampleFunction1() {
    global g_CurrentMode := "media"
    ToolTip("已切换到媒体控制模式`n左键:播放/暂停 中键:静音 滚轮:音量 右键:恢复")
    SetTimer(() => ToolTip(), 2000)
}

#HotIf g_CurrentMode = "media"
RButton::
{
    global g_CurrentMode := "normal"
    ToolTip("已恢复原始热键模式")
    SetTimer(() => ToolTip(), 2000)
    RButtonDo()
    return
}

LButton::
{
    Send "{Media_Play_Pause}"
    return
}

MButton::
{
    Send "{Volume_Mute}"
    return
}

WheelUp::
{
    Send "{Volume_Up}"
    return
}

WheelDown::
{
    Send "{Volume_Down}"
    return
}
#HotIf

ExampleFunction2() {
    global g_CurrentMode := "example2"
    ToolTip("已切换到示例模式2`n左键:功能A 中键:功能B 滚轮:功能C 右键:恢复")
    SetTimer(() => ToolTip(), 2000)
}

#HotIf g_CurrentMode = "example2"
RButton::
{
    global g_CurrentMode := "normal"
    ToolTip("已恢复原始热键模式")
    SetTimer(() => ToolTip(), 2000)
    RButtonDo()
    return
}

LButton::
{
    MsgBox "执行示例模式2的功能A"
    return
}

MButton::
{
    MsgBox "执行示例模式2的功能B"
    return
}

WheelUp::
{
    MsgBox "执行示例模式2的功能C（滚轮上）"
    return
}

WheelDown::
{
    MsgBox "执行示例模式2的功能C（滚轮下）"
    return
}
#HotIf
