#Requires AutoHotkey v2.0

ActivateWXWorkExe() {
    static s_WxWorkFlag := 0
    if WinActive("ahk_exe mstsc.exe") {
        Send("^!{Home}")
    }
    if (WinExist("ahk_exe WXWork.exe")) {
        WinActivate("ahk_exe WXWork.exe")
        Send("^!+{F1}")
        if (s_WxWorkFlag = 0) {
            SetTimer(ShowTimedTooltip.Bind("Set ShortCut For WXWork: <Ctrl-Alt-Shift-F1>"), -100)
        }
        s_WxWorkFlag := 1
    }
}

JumpOutSideOffMsTsc() {
    loop 10 {
        if WinActive("ahk_exe mstsc.exe") {
            try {
                WinActivate("ahk_class Shell_TrayWnd")
            }
            if (not WinActive("ahk_exe mstsc.exe")) {
                if (MonitorGetCount() <= 1) {
                    WinMinimize("ahk_exe mstsc.exe")
                }
                Break
            }
        }
    }
    loop 10 {
        if WinActive("ahk_class Windows.UI.Core.CoreWindow") {
            Send("{Esc}")
        }
        if (not WinActive("ahk_class Windows.UI.Core.CoreWindow")) {
            Break
        }
    }
}
