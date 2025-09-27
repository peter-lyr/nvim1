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

^!t:: {
    if FileExist(A_ScriptDir "\mouse.exe") != "A" {
        CmdRunSilent(A_ScriptDir . "\mouse2exe.bat")
    } else {
        CmdRunSilent(A_ScriptDir . "\mouse.exe")
    }
    ExitApp
}

^!c:: {
    CompileOAndRun()
}

~MButton:: {
    MouseGetPos(&x, &y)
    if (x >= 0 && x <= 20 && y >= 0 && y <= 20) {
        if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
            mouseExe := A_ScriptDir "\mouse.exe"
            if FileExist(mouseExe) != "A" {
                CmdRunSilent(A_ScriptDir . "\mouse2exe.bat")
            } else {
                CmdRunSilent(mouseExe)
            }
            ExitApp
        }
    }
}

CheckExe()

^Ins::ExitApp
