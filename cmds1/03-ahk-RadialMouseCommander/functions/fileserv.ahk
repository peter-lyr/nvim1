#Requires AutoHotkey v2.0

global fileServExe := "ahk_exe Fileserv.exe"
global fileServActiveWin := 0

ActivateFileserv() {
  if WinExist(fileServExe) {
    WinActivate(fileServExe)
  } else {
    Run(GetWkSw("Fileserv\Fileserv.exe"))
  }
  WinWaitActivate(fileServExe)
}

CloseFileserv() {
  if not WinExist(fileServExe) {
    return
  }
  wid := WinGetId("A")
  ActivateFileserv()
  WinKill(fileServExe)
  WinWaitActivate(wid)
}

RestartFileserv() {
  CloseFileserv()
  ActivateFileserv()
}

RestoreWin() {
  global fileServActiveWin
  If (fileServActiveWin) {
    WinWaitActivate(fileServActiveWin)
    ActivateMstscExe()
  }
}

FileServUpClip() {
  global fileServActiveWin
  wid := WinGetId("A")
  ActivateFileserv()
  Try {
    WinGetPos(&x1, &y1, , , fileServExe)
    MouseGetPos(&x0, &y0)
    MouseClick("Left", x1 + 76, y1 + 36, , 0, "D")
    Sleep(50)
    MouseMove(x0, y0)
    Sleep(50)
    ControlFocus(ControlGetClassNN("上传剪贴板"))
    Sleep(50)
    Send("{Space}")
  }
  fileServActiveWin := wid
  SetTimer(RestoreWin, -2000)
  ActivateMstscExe()
}
