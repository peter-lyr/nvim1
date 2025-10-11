#Requires AutoHotkey v2.0

remote_desktop_exes := [
    "ahk_exe mstsc.exe",
    ; "ahk_exe SunloginClient.exe",
    ; "ahk_exe WindowsSandboxClient.exe",
]

remote_desktop_classes := [
    "ahk_class TscShellContainerClass", ; mstsc.exe
]

remote_desktop_titles := [
    ; "Windows 沙盒",
    ; "Windows Sandbox",
]

CmdRunSilent(cmd) {
    shell := ComObject("WScript.Shell")
    launch := "cmd.exe /c " . cmd
    shell.Run(launch, 0, false)
}

CompileMouseAndRun() {
    CmdRunSilent(A_ScriptDir . "\mouse2exe.bat")
    ExitApp
}

CheckExe() {
    if FileExist(A_ScriptDir "\mouse.exe") != "A" {
        CompileMouseAndRun()
    } else {
        ShowTimedTooltipDo("mouse started", 800)
    }
}

IsCurWinAndMax(exes := [], titles := [], classes :=  []) {
    MouseGetPos(, , &currentHwnd)
    try {
        currentWinId := WinGetId(currentHwnd)
    } catch {
        return 0
    }
    for index, exe in exes {
        if (WinExist(exe) and WinGetId(exe) == currentWinId and WinGetMinMax(exe) == 1) {
            return 1
        }
    }
    for index, c in classes {
        if (WinExist(c) and WinGetId(c) == currentWinId and WinGetMinMax(c) == 1) {
            return 1
        }
    }
    for index, title in titles {
        if (WinExist(title) and WinGetId(title) == currentWinId and WinGetMinMax(title) == 1) {
            return 1
        }
    }
    return 0
}

RemoteDesktopActiveOrRButtonPressed() {
    return IsCurWinAndMax(remote_desktop_exes, remote_desktop_titles, remote_desktop_classes)
}

IsDoubleClick(timeout := 500) {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < timeout) {
        return true
    }
    return false
}

ToggleToOExe() {
    if FileExist(A_ScriptDir "\o.exe") != "A" {
        CmdRunSilent(A_ScriptDir . "\o2exe.bat")
    } else {
        CmdRunSilent(A_ScriptDir . "\o.exe")
    }
    ExitApp
}

GetWkSw(file) {
  Home := EnvGet("USERPROFILE")
  return Home . "\w\wk-sw\" . file
}

WinWaitActivate(win) {
  loop 100 {
    if WinExist(win) {
      WinActivate(win)
      if WinActive(win) {
        return 1
      }
    }
  }
  return 0
}

ActivateMstscExe() {
  if WinExist("ahk_exe mstsc.exe") {
    loop 6 {
      WinActivate("ahk_exe mstsc.exe")
      if WinActive("ahk_exe mstsc.exe") {
        break
      }
    }
  }
}

SendAfterActivate(keys) {
    if ActivateTargetWindow()
        Send(keys)
}

GetExplorerPath() {
    activeClass := WinGetClass("A")
    if (activeClass = "CabinetWClass" || activeClass = "ExploreWClass") {
        try {
            for window in ComObject("Shell.Application").Windows {
                if window.hwnd = WinGetID("A") {
                    currentPath := window.Document.Folder.Self.Path
                    A_Clipboard := currentPath
                    return
                }
            }
        }
        try {
            winTitle := WinGetTitle("A")
            if RegExMatch(winTitle, "([A-Z]:\\.*)", &match) {
                A_Clipboard := match[1]
            }
        }
    }
}

CopyGetPath() {
    Send("^c")
    if !ClipWait(2) {
        MsgBox "复制操作超时或失败"
        return
    }
    Sleep(100)
    clipContent := A_Clipboard
    A_Clipboard := clipContent
    ShowTimedTooltipLaterDo(clipContent)
}
