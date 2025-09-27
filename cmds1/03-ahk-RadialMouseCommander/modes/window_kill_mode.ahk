#Requires AutoHotkey v2.0

g_WindowsNoWinKillAndTaskKill := [
    "ahk_exe explorer.exe",
]

EnterWindowKillMode() {
    ModeActionsSet("window_kill",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
    )
}

#HotIf g_CurrentMode = "window_kill"

LButton:: {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        for _, winTitle in g_WindowsNoWinKillAndTaskKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                if MyWinActivate(windowUnderCursor) {
                    Send("^w")
                }
                return
            }
        }
        if MyWinActivate(windowUnderCursor) {
            Send("!{F4}")
        }
    }
}

MButton:: {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        for _, winTitle in g_WindowsNoWinKillAndTaskKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                return
            }
        }
        winPID := WinGetPID(windowUnderCursor)
        CmdRunSilent("taskkill /f /pid " winPID)
    }
}

#HotIf
