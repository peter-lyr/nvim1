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
        ShowTimedTooltip("mouse started", 800)
    }
}

IsCurWinAndMax(exes := [], titles := [], classes :=  []) {
    MouseGetPos(, , &currentHwnd)
    currentWinId := WinGetId(currentHwnd)
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
