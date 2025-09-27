#Requires AutoHotkey v2.0

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
