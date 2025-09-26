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

WinWaitActivate(win) {
  Loop 1000 {
    If WinExist(win) {
      WinActivate(win)
      If WinActive(win) {
        Return 1
      }
    }
  }
  Return 0
}

ActivateOrOpen(wid, exe) {
  Try {
    If Not WinExist(wid) {
      Run(exe)
    }
    WinWaitActivate(wid)
  }
}

ActivateOrLaunchNvim0104() {
    ActivateOrOpen("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim")
}
