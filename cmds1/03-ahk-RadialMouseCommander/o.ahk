#Requires AutoHotkey v2.0

CmdRunSilent(cmd) {
    shell := ComObject("WScript.Shell")
    launch := "cmd.exe /c " . cmd
    shell.Run(launch, 0, false)
}

CompileOAndRun() {
    CmdRunSilent(A_ScriptDir . "\o2exe.bat")
    ExitApp
}

CheckExe() {
    if FileExist(A_ScriptDir "/o.exe") != "A" {
        CompileOAndRun()
    } else {
        Tooltip("o started")
        SetTimer(Tooltip, -800)
    }
}

IsDoubleClick(timeout := 500) {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < timeout) {
        return true
    }
    return false
}

ToggleToMouseExe() {
    if FileExist(A_ScriptDir "\mouse.exe") != "A" {
        CmdRunSilent(A_ScriptDir . "\mouse2exe.bat")
    } else {
        CmdRunSilent(A_ScriptDir . "\mouse.exe")
    }
    ExitApp
}

^!t:: {
    ToggleToMouseExe()
}

^!c:: {
    CompileOAndRun()
}

~LButton:: {
    MouseGetPos(&x)
    if (x >= 0 && x <= 10) {
        if (IsDoubleClick()) {
            ToggleToMouseExe()
        }
    }
}

CheckExe()

^Ins::ExitApp
