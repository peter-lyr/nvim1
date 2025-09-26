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

ActivateExistedSel(windowList) {
    choices := ""
    windowIDs := []
    for i, windowID in windowList {
        title := WinGetTitle("ahk_id " windowID)
        windowIDs.Push(windowID)
        choices .= i ". " title "`n"
    }
    choice := InputBox("请选择要激活的窗口：`n`n" choices, "选择窗口", "w400 h300")
    if (choice.Result = "OK" && IsNumber(choice.Value) && choice.Value >= 1 && choice.Value <= windowList.Length) {
        selectedID := windowIDs[choice.Value]
        WinActivate("ahk_id " selectedID)
        if (WinWaitActive("ahk_id " selectedID, , 2)) {
            return true
        }
    }
    return false
}

ActivateExisted(windowTitle) {
    if (not WinExist(windowTitle)) {
        return false
    }
    WinActivate(windowTitle)
    if (WinWaitActive(windowTitle, , 2)) {
        return true
    }
    return false
}

ActivateOrRun(windowTitle, appPath) {
    if (WinExist(windowTitle)) {
        ActivateExisted(windowTitle)
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
    DetectHiddenWindows False
    windowList := WinGetList(windowTitle)
    if (windowList.Length > 0) {
        if (windowList.Length > 1) {
            activeWindowID := WinGetID("A")
            filteredList := []
            for windowID in windowList {
                if (windowID != activeWindowID) {
                    filteredList.Push(windowID)
                }
            }
            if (filteredList.Length = 0) {
                RunInWinR(windowTitle, appPath)
            } else if (filteredList.Length = 1) {
                if (ActivateExisted("ahk_id " filteredList[1])) {
                    return true
                }
            } else {
                if (ActivateExistedSel(filteredList)) {
                    return true
                }
            }
        } else {
            if (ActivateExisted("ahk_id " windowList[1])) {
                return true
            }
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
