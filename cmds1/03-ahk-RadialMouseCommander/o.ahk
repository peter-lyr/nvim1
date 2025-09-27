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

CheckExe()

^Ins::ExitApp
