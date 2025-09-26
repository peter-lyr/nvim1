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

ActivateOrLaunch(windowTitle, appPath) {
    if (WinExist(windowTitle)) {
        WinActivate(windowTitle)
        if (WinWaitActive(windowTitle, , 2)) {
            return true
        }
    } else {
        Run(appPath)
        if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
            WinActivate(windowTitle)
            return true
        }
    }
    return false
}

RunInWinR(windowTitle, appPath) {
    ClipboardOld := A_Clipboard
    Sleep(50)
    A_Clipboard := ""
    A_Clipboard := appPath
    if !ClipWait(2) {
        A_Clipboard := ClipboardOld
        ClipboardOld := ""
        return false
    }
    Send("#r")
    if !WinWait("Run", , 3) {
        A_Clipboard := ClipboardOld
        ClipboardOld := ""
        return false
    }
    WinActivate("Run")
    Sleep(200)
    Send("^v")
    Sleep(300)
    Send("{Enter}")
    SetTimer(RestoreClipboard.Bind(ClipboardOld), -1000)
    if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
        WinActivate(windowTitle)
        return true
    }
    return false
}


ActivateOrRunInWinR(windowTitle, appPath) {
    if (WinExist(windowTitle)) {
        WinActivate(windowTitle)
        if (WinWaitActive(windowTitle, , 2)) {
            return true
        }
    } else {
        RunInWinR(windowTitle, appPath)
    }
    return false
}

RestoreClipboard(ClipboardOld) {
    A_Clipboard := ClipboardOld
    ClipboardOld := ""
    Sleep(50)
}
