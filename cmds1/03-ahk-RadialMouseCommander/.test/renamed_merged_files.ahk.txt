#Requires AutoHotkey v2.0

global fileServExe := "ahk_exe Fileserv.exe"
global fileServActiveWin := 0

global g_PreviousRadialMenuTooltip := ""
global g_IsRadialMenuTooltipUpdateEnabled := 1
global g_IsTimedTooltipDisplayEnabled := 1

global g_WindowResizeState := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMovementState := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

global g_CurrentOperationMode := "normal"

global g_TargetWindowList := []
global g_CurrentWindowIndex := 0
global g_LastMousePos := {x: 0, y: 0}
global g_LastActiveWindowHwnd := 0
global g_OriginalWindowTransparency := Map()
global g_TargetWindowActivateOpacity := 180
global g_WindowOpacityRestoreTimer := 0

global g_RadialMenuGuiObj := ""
global g_RadialMenuGuiObjHwnd := 0
global g_RadialMenuRadiusPx := 5
global g_RadialMenuCenterPosX := 0
global g_RadialMenuCenterPosY := 0
global g_CapturedWindowHwnd := 0
global g_CapturedMouseClickPosX := 0
global g_CapturedMouseClickPosY := 0

global g_LeftMouseButtonState := 0, g_MiddleMouseButtonState := 0, g_WheelMouseButtonState := 0
global g_MaxLeftMouseButtonStates := 1, g_MaxMiddleMouseButtonStates := 1, g_MaxWheelMouseButtonStates := 1

global g_DirectionSymbols := Map(
    "R", "→",
    "RD", "↘",
    "D", "↓",
    "LD", "↙",
    "L", "←",
    "LU", "↖",
    "U", "↑",
    "RU", "↗"
)

global g_DirectionNames := Map(
    "R", "右",
    "RD", "右下",
    "D", "下",
    "LD", "左下",
    "L", "左",
    "LU", "左上",
    "U", "上",
    "RU", "右上"
)

global g_OperationModeActionMap := Map()

InitNormalOperationModeActions()
ShowRadialMenuAtCursorPos()
HideRadialMenu()

^Ins::ExitApp

#Requires AutoHotkey v2.0

ActivateFileServWindow() {
  if WinExist(fileServExe) {
    WinActivate(fileServExe)
  } else {
    Run(GetWkSwFilePath("Fileserv\Fileserv.exe"))
  }
  WaitForWindowAndActivate(fileServExe)
}

CloseFileServWindow() {
  if not WinExist(fileServExe) {
    return
  }
  wid := WinGetId("A")
  ActivateFileServWindow()
  WinKill(fileServExe)
  WaitForWindowAndActivate(wid)
}

RestartFileServProcess() {
  CloseFileServWindow()
  ActivateFileServWindow()
}

RestorePreviouslyActiveWindow() {
  global fileServActiveWin
  If (fileServActiveWin) {
    WaitForWindowAndActivate(fileServActiveWin)
    ActivateRemoteDesktopExe()
  }
}

UploadClipboardToFileServ() {
  global fileServActiveWin
  wid := WinGetId("A")
  ActivateFileServWindow()
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
  SetTimer(RestorePreviouslyActiveWindow, -2000)
  ActivateRemoteDesktopExe()
}

#Requires AutoHotkey v2.0

CreateRadialMenuGuiObj(centerX, centerY, width, height, transparency, backgroundColor) {
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数（当前宽：" width "，高：" height "）")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间（当前值：" transparency "）")
    positionX := centerX - width / 2
    positionY := centerY - height / 2
    radialMenuGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    radialMenuGui.BackColor := backgroundColor
    radialMenuGui.Show("x" positionX " y" positionY " w" width " h" height " NoActivate")
    WinSetTransparent(transparency, radialMenuGui.Hwnd)
    ellipticalRegion := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0,
        "Int", width,
        "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", radialMenuGui.Hwnd, "Ptr", ellipticalRegion, "Int", 1)
    return radialMenuGui
}

ShowRadialMenuAtCursorPos() {
    global g_RadialMenuGuiObj, g_RadialMenuGuiObjHwnd, g_RadialMenuRadiusPx, g_RadialMenuCenterPosX, g_RadialMenuCenterPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    g_RadialMenuCenterPosX := cursorX
    g_RadialMenuCenterPosY := cursorY
    menuDiameter := g_RadialMenuRadiusPx * 2
    if (g_RadialMenuGuiObj && IsObject(g_RadialMenuGuiObj)) {
        menuX := cursorX - g_RadialMenuRadiusPx
        menuY := cursorY - g_RadialMenuRadiusPx
        g_RadialMenuGuiObj.Show("x" menuX " y" menuY " w" menuDiameter " h" menuDiameter " NoActivate")
        g_RadialMenuGuiObjHwnd := g_RadialMenuGuiObj.Hwnd
    } else {
        try {
            g_RadialMenuGuiObj := CreateRadialMenuGuiObj(cursorX, cursorY, menuDiameter, menuDiameter, 180, "FF0000")
            g_RadialMenuGuiObjHwnd := g_RadialMenuGuiObj.Hwnd
        }
        catch as e {
            ShowTemporaryTooltip("创建圆形菜单失败: " . e.Message)
            g_RadialMenuGuiObj := ""
            g_RadialMenuGuiObjHwnd := 0
        }
    }
}

HideRadialMenu() {
    global g_RadialMenuGuiObj
    if (g_RadialMenuGuiObj && IsObject(g_RadialMenuGuiObj)) {
        g_RadialMenuGuiObj.Hide()
    }
}

IsCursorWithinRadialMenu() {
    global g_RadialMenuGuiObjHwnd, g_RadialMenuRadiusPx, g_RadialMenuCenterPosX, g_RadialMenuCenterPosY
    if (!g_RadialMenuGuiObjHwnd)
        return false
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    distanceFromCenter := Sqrt((cursorX - g_RadialMenuCenterPosX)**2 + (cursorY - g_RadialMenuCenterPosY)**2)
    return distanceFromCenter <= g_RadialMenuRadiusPx
}

CalculateCursorDirRelativeToRadialMenu() {
    global g_RadialMenuCenterPosX, g_RadialMenuCenterPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    deltaX := cursorX - g_RadialMenuCenterPosX
    deltaY := cursorY - g_RadialMenuCenterPosY
    angleDegrees := DllCall("msvcrt.dll\atan2", "Double", deltaY, "Double", deltaX, "Double") * 57.29577951308232
    if (angleDegrees < 0)
        angleDegrees += 360
    if (angleDegrees >= 337.5 || angleDegrees < 22.5)
        return "R"
    else if (angleDegrees >= 22.5 && angleDegrees < 67.5)
        return "RD"
    else if (angleDegrees >= 67.5 && angleDegrees < 112.5)
        return "D"
    else if (angleDegrees >= 112.5 && angleDegrees < 157.5)
        return "LD"
    else if (angleDegrees >= 157.5 && angleDegrees < 202.5)
        return "L"
    else if (angleDegrees >= 202.5 && angleDegrees < 247.5)
        return "LU"
    else if (angleDegrees >= 247.5 && angleDegrees < 292.5)
        return "U"
    else if (angleDegrees >= 292.5 && angleDegrees < 337.5)
        return "RU"
}

GetDirectionChineseDisplayName(directionCode) {
    global g_DirectionNames
    return g_DirectionNames.Has(directionCode) ? g_DirectionNames[directionCode] : directionCode
}

GetDirectionSymbol(directionCode) {
    global g_DirectionSymbols
    return g_DirectionSymbols.Has(directionCode) ? g_DirectionSymbols[directionCode] : "•"
}

GetMouseBtnStateAndDirection() {
    global g_LeftMouseButtonState, g_MiddleMouseButtonState, g_WheelMouseButtonState
    direction := CalculateCursorDirRelativeToRadialMenu()
    return g_LeftMouseButtonState "" g_MiddleMouseButtonState "" g_WheelMouseButtonState "" direction
}

GetCurrentOperationModeActionMap() {
    global g_OperationModeActionMap, g_CurrentOperationMode
    if (!g_OperationModeActionMap.Has(g_CurrentOperationMode)) {
        return g_OperationModeActionMap["normal"]
    }
    return g_OperationModeActionMap[g_CurrentOperationMode]
}

GenerateRadialMenuTooltipText() {
    global g_LeftMouseButtonState, g_MiddleMouseButtonState, g_WheelMouseButtonState
    actionMap := GetCurrentOperationModeActionMap()
    directionLayout := [
        ["", "U", ""],
        ["LU", "", "RU"],
        ["L", "", "R"],
        ["LD", "", "RD"],
        ["", "D", ""]
    ]
    displayGrid := []
    for row in directionLayout {
        newRow := []
        for directionCode in row {
            if (directionCode = "") {
                newRow.Push("")
                continue
            }
            stateKey := g_LeftMouseButtonState "" g_MiddleMouseButtonState "" g_WheelMouseButtonState "" directionCode
            actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
            actionDescription := actionInfo[1]
            directionSymbol := GetDirectionSymbol(directionCode)
            directionName := GetDirectionChineseDisplayName(directionCode)
            displayText := directionSymbol " " directionName ":" actionDescription
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }
    displayText := "模式: " g_CurrentOperationMode " 状态: 左键=" g_LeftMouseButtonState ", 中键=" g_MiddleMouseButtonState ", 滚轮=" g_WheelMouseButtonState "`n`n"
    for row in displayGrid {
        line := ""
        for column in row {
            if (column = "") {
                line .= "        "
            } else {
                targetWidth := 20
                currentWidth := StrLen(column)
                if (currentWidth >= targetWidth) {
                    line .= column
                } else {
                    spacesNeeded := targetWidth - currentWidth
                    leftSpaces := spacesNeeded // 2
                    rightSpaces := spacesNeeded - leftSpaces
                    loop leftSpaces {
                        line .= " "
                    }
                    line .= column
                    loop rightSpaces {
                        line .= " "
                    }
                }
            }
        }
        displayText .= line "`n"
    }
    return displayText
}

GenerateCursorDirectionInfo() {
    directionCode := CalculateCursorDirRelativeToRadialMenu()
    directionSymbol := GetDirectionSymbol(directionCode)
    directionName := GetDirectionChineseDisplayName(directionCode)
    stateKey := GetMouseBtnStateAndDirection()
    actionMap := GetCurrentOperationModeActionMap()
    actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
    actionDescription := actionInfo[1]
    return "模式: " g_CurrentOperationMode " 方向: " directionSymbol " " directionName "`n操作: " actionDescription
}

CycleLeftMouseButtonState() {
    global g_LeftMouseButtonState, g_MaxLeftMouseButtonStates
    g_LeftMouseButtonState := Mod(g_LeftMouseButtonState + 1, g_MaxLeftMouseButtonStates + 1)
}

CycleMiddleMouseButtonState() {
    global g_MiddleMouseButtonState, g_MaxMiddleMouseButtonStates
    g_MiddleMouseButtonState := Mod(g_MiddleMouseButtonState + 1, g_MaxMiddleMouseButtonStates + 1)
}

CycleWheelMouseButtonState() {
    global g_WheelMouseButtonState, g_MaxWheelMouseButtonStates
    g_WheelMouseButtonState := Mod(g_WheelMouseButtonState + 1, g_MaxWheelMouseButtonStates + 1)
}

CaptureWindowUnderCursorPos() {
    global g_CapturedMouseClickPosX, g_CapturedMouseClickPosY, g_CapturedWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(&g_CapturedMouseClickPosX, &g_CapturedMouseClickPosY, &g_CapturedWindowHwnd)
}

ResetAllMouseButtonStates() {
    global g_LeftMouseButtonState := 0
    global g_MiddleMouseButtonState := 0
    global g_WheelMouseButtonState := 0
}

ExecuteSelectedRadialMenuAction() {
    stateKey := GetMouseBtnStateAndDirection()
    actionMap := GetCurrentOperationModeActionMap()
    if (actionMap.Has(stateKey)) {
        actionInfo := actionMap[stateKey]
        actionFunction := actionInfo[2]
        try {
            actionFunction()
        } catch as e {
            ShowTemporaryTooltip("执行操作时出错: " e.Message " [" actionInfo[1] "]")
        }
    } else {
        ShowTemporaryTooltip("未定义的操作: " stateKey)
    }
}

#Requires AutoHotkey v2.0

ToggleRadialMenuTooltipUpdate() {
    global g_IsRadialMenuTooltipUpdateEnabled
    g_IsRadialMenuTooltipUpdateEnabled := 1 -g_IsRadialMenuTooltipUpdateEnabled
}

ToggleTimedTooltipDisplay() {
    global g_IsTimedTooltipDisplayEnabled
    g_IsTimedTooltipDisplayEnabled := 1 -g_IsTimedTooltipDisplayEnabled
}

ShowTemporaryTooltip(message, timeout := 2000) {
    global g_IsTimedTooltipDisplayEnabled
    if not g_IsTimedTooltipDisplayEnabled {
        return
    }
    ToolTip(message)
    SetTimer(() => ToolTip(), -timeout)
}

UpdateRadialMenuTooltipContent() {
    global g_PreviousRadialMenuTooltip
    global g_IsRadialMenuTooltipUpdateEnabled
    if not g_IsRadialMenuTooltipUpdateEnabled {
        return
    }
    if (IsCursorWithinRadialMenu()) {
        newContent := GenerateRadialMenuTooltipText()
    } else {
        newContent := GenerateCursorDirectionInfo()
    }
    if (newContent != g_PreviousRadialMenuTooltip) {
        ToolTip(newContent)
        g_PreviousRadialMenuTooltip := newContent
    }
}

InitializeRadialMenuTooltip() {
    global g_PreviousRadialMenuTooltip := ""
    SetTimer(UpdateRadialMenuTooltipContent, 10)
}

CleanupRadialMenuTooltip() {
    ToolTip()
    SetTimer(UpdateRadialMenuTooltipContent, 0)
    global g_PreviousRadialMenuTooltip := ""
}

#Requires AutoHotkey v2.0

g_RemoteDesktopExeList := [
    "ahk_exe mstsc.exe",
]

g_RemoteDesktopClassList := [
    "ahk_class TscShellContainerClass",
]

g_RemoteDesktopTitleList := [
]

RunCommandSilently(cmd) {
    shell := ComObject("WScript.Shell")
    launch := "cmd.exe /c " . cmd
    shell.Run(launch, 0, false)
}

CompileMouseScriptAndRun() {
    RunCommandSilently(A_ScriptDir . "\mouse2exe.bat")
    ExitApp
}

CheckMouseExeExists() {
    if FileExist(A_ScriptDir "\mouse.exe") != "A" {
        CompileMouseScriptAndRun()
    } else {
        ShowTemporaryTooltip("mouse started", 800)
    }
}

IsCurrentWindowMaximized(exes := [], titles := [], classes :=  []) {
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

IsRemoteDesktopActiveOrRBtnPressed() {
    return IsCurrentWindowMaximized(g_RemoteDesktopExeList, g_RemoteDesktopTitleList, g_RemoteDesktopClassList)
}

IsDoubleClickEvent(timeout := 500) {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < timeout) {
        return true
    }
    return false
}

ToggleOrRunOExe() {
    if FileExist(A_ScriptDir "\o.exe") != "A" {
        RunCommandSilently(A_ScriptDir . "\o2exe.bat")
    } else {
        RunCommandSilently(A_ScriptDir . "\o.exe")
    }
    ExitApp
}

GetWkSwFilePath(file) {
  Home := EnvGet("USERPROFILE")
  return Home . "\w\wk-sw\" . file
}

WaitForWindowAndActivate(win) {
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

ActivateRemoteDesktopExe() {
  if WinExist("ahk_exe mstsc.exe") {
    loop 6 {
      WinActivate("ahk_exe mstsc.exe")
      if WinActive("ahk_exe mstsc.exe") {
        break
      }
    }
  }
}

#Requires AutoHotkey v2.0

TryActivateWindow(winTitle) {
    WinWaitActive(winTitle, , 0.1)
    if (!WinActive(winTitle)) {
        WinActivate(winTitle)
    }
    if (WinActive(winTitle)) {
        return true
    }
    return false
}

ActivateWXWorkApp() {
    static s_WxWorkFlag := 0
    if WinActive("ahk_exe mstsc.exe") {
        Send("^!{Home}")
    }
    if (WinExist("ahk_exe WXWork.exe")) {
        WinActivate("ahk_exe WXWork.exe")
        Send("^!+{F1}")
        if (s_WxWorkFlag = 0) {
            SetTimer(ShowTemporaryTooltip.Bind("Set ShortCut For WXWork: <Ctrl-Alt-Shift-F1>"), -100)
        }
        s_WxWorkFlag := 1
    }
}

ExitRemoteDesktopFullscreenMode() {
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

ActivateSelectedWindowFromList(windowList) {
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

TryActivateExistingWindow(windowTitle) {
    if (not WinExist(windowTitle)) {
        return false
    }
    WinActivate(windowTitle)
    if (WinWaitActive(windowTitle, , 2)) {
        return true
    }
    return false
}

ActivateOrLaunchWindow(windowTitle, appPath) {
    static lastActivation := Map()
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
                Run(appPath)
                if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
                    WinActivate(windowTitle)
                    return true
                }
            } else if (filteredList.Length = 1) {
                if (TryActivateExistingWindow("ahk_id " filteredList[1])) {
                    lastActivation[windowTitle] := 0
                    for windowID in windowList {
                        if (windowID != filteredList[1]) {
                            try {
                                WinMinimize("ahk_id " windowID)
                            }
                        }
                    }
                    return true
                }
            } else {
                if (!lastActivation.Has(windowTitle)) {
                    lastActivation[windowTitle] := 0
                }
                nextIndex := lastActivation[windowTitle] + 1
                if (nextIndex >= filteredList.Length) {
                    nextIndex := 0
                }
                if (TryActivateExistingWindow("ahk_id " filteredList[nextIndex + 1])) {
                    lastActivation[windowTitle] := nextIndex
                    for windowID in windowList {
                        if (windowID != filteredList[nextIndex + 1]) {
                            try {
                                WinMinimize("ahk_id " windowID)
                            }
                        }
                    }
                    return true
                }
            }
        } else {
            if (TryActivateExistingWindow("ahk_id " windowList[1])) {
                lastActivation[windowTitle] := 0
                for windowID in windowList {
                    if (windowID != windowList[1]) {
                        try {
                            WinMinimize("ahk_id " windowID)
                        }
                    }
                }
                return true
            }
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

RestoreOriginalClipboard(ClipboardOld) {
    A_Clipboard := ClipboardOld
    ClipboardOld := ""
    Sleep(50)
}

LaunchAppViaWinRDialog(windowTitle, appPath) {
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
    SetTimer(RestoreOriginalClipboard.Bind(ClipboardOld), -1000)
    if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
        WinActivate(windowTitle)
        return true
    }
    return false
}

ActivateOrLaunchWindowInWinR(windowTitle, appPath) {
    static lastActivation := Map()
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
                LaunchAppViaWinRDialog(windowTitle, appPath)
            } else if (filteredList.Length = 1) {
                if (TryActivateExistingWindow("ahk_id " filteredList[1])) {
                    lastActivation[windowTitle] := 0
                    for windowID in windowList {
                        if (windowID != filteredList[1]) {
                            try {
                                WinMinimize("ahk_id " windowID)
                            }
                        }
                    }
                    return true
                }
            } else {
                if (!lastActivation.Has(windowTitle)) {
                    lastActivation[windowTitle] := 0
                }
                nextIndex := lastActivation[windowTitle] + 1
                if (nextIndex >= filteredList.Length) {
                    nextIndex := 0
                }
                if (TryActivateExistingWindow("ahk_id " filteredList[nextIndex + 1])) {
                    lastActivation[windowTitle] := nextIndex
                    for windowID in windowList {
                        if (windowID != filteredList[nextIndex + 1]) {
                            try {
                                WinMinimize("ahk_id " windowID)
                            }
                        }
                    }
                    return true
                }
            }
        } else {
            if (TryActivateExistingWindow("ahk_id " windowList[1])) {
                lastActivation[windowTitle] := 0
                for windowID in windowList {
                    if (windowID != windowList[1]) {
                        try {
                            WinMinimize("ahk_id " windowID)
                        }
                    }
                }
                return true
            }
        }
    } else {
        LaunchAppViaWinRDialog(windowTitle, appPath)
    }
    return false
}

#Requires AutoHotkey v2.0

;;桌面不透明化
g_WindowsExemptFromTransparency := [
    "ahk_class tooltips_class32",
    GetDesktopWindowClass(),
]

GetDesktopWindowClass() {
    Loop {
        hwnd := WinExist("ahk_class WorkerW")
        if !hwnd
            break
        if ControlGetHwnd("SHELLDLL_DefView1", hwnd) {
            return "ahk_class WorkerW"
        }
    }
    if WinExist("ahk_class Progman")
        return "ahk_class Progman"
    return 0
}

ActivateCapturedWindow() {
    global g_CapturedWindowHwnd
    WinActivate(g_CapturedWindowHwnd)
}

ToggleCapturedWindowTopmost(hwnd := 0) {
    global g_CapturedWindowHwnd
    if not hwnd {
        hwnd := g_CapturedWindowHwnd
    }
    if (hwnd) {
        currentStyle := WinGetExStyle(hwnd)
        isTopmost := (currentStyle & 0x8)
        if (isTopmost) {
            WinSetAlwaysOnTop false, hwnd
            ShowTemporaryTooltip("取消窗口置顶")
        } else {
            WinSetAlwaysOnTop true, hwnd
            ShowTemporaryTooltip("窗口已置顶")
        }
    } else {
        ShowTemporaryTooltip("没有找到目标窗口")
    }
}

MinimizeCapturedWindow(hwnd := 0) {
    global g_CapturedWindowHwnd
    if not hwnd {
        hwnd := g_CapturedWindowHwnd
    }
    if WinExist(hwnd) = WinExist(GetDesktopWindowClass()) {
        return ;;桌面不最小化
    }
    WinMinimize(hwnd)
}

ToggleCapturedWindowMaximize(hwnd := 0) {
    global g_CapturedWindowHwnd
    if not hwnd {
        hwnd := g_CapturedWindowHwnd
    }
    if (WinGetMinMax(hwnd) = 1) {
        WinRestore(hwnd)
    } else {
        WinMaximize(hwnd)
    }
}

ClickAtCapturedMousePos() {
    global g_CapturedMouseClickPosX, g_CapturedMouseClickPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_CapturedMouseClickPosX, g_CapturedMouseClickPosY, "Left")
    MouseMove(originalX, originalY, 0)
}

DecreaseWindowOpacity(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    for _, winTitle in g_WindowsExemptFromTransparency {
        if hwnd = WinExist(winTitle) {
            return
        }
    }
    currentTransparency := WinGetTransparent(hwnd)
    if (currentTransparency = "")
        currentTransparency := 255
    newTransparency := currentTransparency - 15
    if (newTransparency < 30)
        newTransparency := 30
    WinSetTransparent newTransparency, hwnd
    ShowTemporaryTooltip("透明度: " newTransparency)
}

IncreaseWindowOpacity(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    for _, winTitle in g_WindowsExemptFromTransparency {
        if hwnd = WinExist(winTitle) {
            return
        }
    }
    currentTransparency := WinGetTransparent(hwnd)
    if (currentTransparency = "")
        currentTransparency := 255
    newTransparency := currentTransparency + 15
    if (newTransparency > 255)
        newTransparency := 255
    WinSetTransparent newTransparency, hwnd
    ShowTemporaryTooltip("透明度: " newTransparency)
}

#Requires AutoHotkey v2.0

^#k:: {
    ToggleCapturedWindowMaximize("A")
}

^#j:: {
    MinimizeCapturedWindow("A")
}

^#m:: {
    ToggleCapturedWindowTopmost("A")
}

^#h:: {
    DecreaseWindowOpacity("A")
}

^#l:: {
    IncreaseWindowOpacity("A")
}

#Requires AutoHotkey v2.0

g_IsMenuModeActive := false
g_CurrentMenuType := "normal"
g_LastAltKeyPressTime := 0
g_MenuDoubleClickTimeoutMs := 300
g_MenuAutoExitTimer := 0
g_MenuAutoExitTimeoutMs := 8000

g_MenuDefinitionsMap := Map(
    "normal", Map(
        "q", ["打开企业微信", ActivateWXWorkApp, false],
        ",", ["打开或激活nvim-0.10.4", ActivateOrLaunchWindowInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), true],
        ".", ["打开或激活nvim-0.11.4", ActivateOrLaunchWindow.Bind("ahk_exe nvim-qt.exe", "nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), true],
        "/", ["激活mstsc", TryActivateExistingWindow.Bind("ahk_exe mstsc.exe"), false],
        "f", ["fileserv", SwitchToTargetMenuType.Bind("fileserv"), true],
        "a", ["activate", SwitchToTargetMenuType.Bind("activate"), true],
        "r", ["run", SwitchToTargetMenuType.Bind("run"), true],
    ),
    "fileserv", Map(
        "f", ["打开或激活fileserv", ActivateFileServWindow, false],
        "k", ["CloseFileServWindow", CloseFileServWindow, false],
        "r", ["RestartFileServProcess", RestartFileServProcess, false],
        "u", ["UploadClipboardToFileServ", UploadClipboardToFileServ, false],
        "n", ["normal", SwitchToTargetMenuType.Bind("normal"), true],
    ),
    "activate", Map(
        ",", ["打开或激活nvim-0.10.4", ActivateOrLaunchWindowInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), true],
        ".", ["打开或激活nvim-0.11.4", ActivateOrLaunchWindow.Bind("ahk_exe nvim-qt.exe", "nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), true],
        "/", ["激活mstsc", TryActivateExistingWindow.Bind("ahk_exe mstsc.exe"), false],
        "n", ["normal", SwitchToTargetMenuType.Bind("normal"), true],
    ),
    "run", Map(
        ",", ["打开nvim-0.10.4", LaunchAppViaWinRDialog.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), false],
        ".", ["打开nvim-0.11.4", Run.Bind("nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), false],
        "n", ["normal", SwitchToTargetMenuType.Bind("normal"), true],
    ),
)

~LAlt:: {
    global g_IsMenuModeActive, g_LastAltKeyPressTime, g_MenuDoubleClickTimeoutMs
    currentTime := A_TickCount
    if (currentTime - g_LastAltKeyPressTime < g_MenuDoubleClickTimeoutMs && !g_IsMenuModeActive) {
        ExitRemoteDesktopFullscreenMode()
        EnterMenuOperationMode("normal")
    }
    g_LastAltKeyPressTime := currentTime
}

EnterMenuOperationMode(menuType) {
    global g_IsMenuModeActive, g_CurrentMenuType, g_MenuAutoExitTimer, g_MenuAutoExitTimeoutMs, g_MenuDefinitionsMap
    if (g_IsMenuModeActive) {
        return
    }
    g_IsMenuModeActive := true
    g_CurrentMenuType := menuType
    if (g_MenuDefinitionsMap.Has(menuType)) {
        ShowMenuOperationTooltip(g_MenuDefinitionsMap[menuType], menuType . "菜单")
    } else {
        ShowMenuOperationTooltip(Map(), "未知菜单")
    }
    RegisterMenuSpecificHotkeys(menuType)
    Hotkey("Escape", ExitMenuOperationMode, "On")
    g_MenuAutoExitTimer := SetTimer(ExitMenuOperationMode, -g_MenuAutoExitTimeoutMs)
}

ExitMenuOperationMode(*) {
    global g_IsMenuModeActive, g_MenuAutoExitTimer
    if (!g_IsMenuModeActive) {
        return
    }
    g_IsMenuModeActive := false
    if (g_MenuAutoExitTimer) {
        SetTimer(g_MenuAutoExitTimer, 0)
        g_MenuAutoExitTimer := 0
    }
    UnregisterAllMenuHotkeys()
    ToolTip()
    Hotkey("Escape", "Off")
}

RegisterMenuSpecificHotkeys(menuType) {
    global g_MenuDefinitionsMap
    if (g_MenuDefinitionsMap.Has(menuType)) {
        for key, value in g_MenuDefinitionsMap[menuType] {
            Hotkey(key, HandleMenuHotkeyPress.Bind(key, menuType), "On")
        }
    }
}

UnregisterAllMenuHotkeys() {
    global g_MenuDefinitionsMap
    for menuName, hotkeyMap in g_MenuDefinitionsMap {
        for key in hotkeyMap {
            try Hotkey(key, "Off")
        }
    }
}

ShowMenuOperationTooltip(hotkeyMap, menuName) {
    global g_MenuAutoExitTimeoutMs
    tooltipText := menuName . "（" . g_MenuAutoExitTimeoutMs//1000 . "秒后自动退出，按ESC立即退出）`n"
    for key, value in hotkeyMap {
        tooltipText .= "[" key "] " value[1]
        if (value[3]) {
            tooltipText .= " (维持菜单)"
        }
        tooltipText .= "`n"
    }
    ToolTip(tooltipText)
}

HandleMenuHotkeyPress(key, menuType, *) {
    global g_CurrentMenuType, g_MenuAutoExitTimer, g_MenuAutoExitTimeoutMs, g_MenuDefinitionsMap
    if (g_CurrentMenuType != menuType) {
        return
    }
    if (g_MenuDefinitionsMap.Has(menuType) && g_MenuDefinitionsMap[menuType].Has(key)) {
        action := g_MenuDefinitionsMap[menuType][key][2]
        action.Call()
        if (!g_MenuDefinitionsMap[menuType][key][3]) {
            ExitMenuOperationMode()
        } else {
            if (g_MenuAutoExitTimer) {
                SetTimer(g_MenuAutoExitTimer, 0)
            }
            g_MenuAutoExitTimer := SetTimer(ExitMenuOperationMode, -g_MenuAutoExitTimeoutMs)
        }
    }
}

SwitchToTargetMenuType(targetMenu) {
    global g_IsMenuModeActive, g_CurrentMenuType, g_MenuAutoExitTimer, g_MenuDefinitionsMap
    if (!g_IsMenuModeActive || g_CurrentMenuType = targetMenu || !g_MenuDefinitionsMap.Has(targetMenu)) {
        return
    }
    if (g_MenuAutoExitTimer) {
        SetTimer(g_MenuAutoExitTimer, 0)
        g_MenuAutoExitTimer := 0
    }
    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    g_IsMenuModeActive := false
    EnterMenuOperationMode(targetMenu)
}

OnExit((*) => ExitMenuOperationMode())

#Requires AutoHotkey v2.0

InitNormalOperationModeActions() {
    SetOperationModeActions("normal",
        ;;以下3个最常用
        "000RU", ["切换最大化窗口", ToggleCapturedWindowMaximize],
        "000RD", ["最小化窗口", MinimizeCapturedWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        ;;各种模式
        "000LU", ["窗口控制模式2", EnterBasicWindowControlMode2],
        "000U", ["窗口激活模式", EnterWindowActivationMode],
        ;;待替换
        "000D", ["向下移动光标", Send.Bind("{Down}")],
        "000L", ["向左移动光标", Send.Bind("{Left}")],
        "000R", ["向右移动光标", Send.Bind("{Right}")],
        ;;配置
        "010R", ["切换菜单提示", ToggleRadialMenuTooltipUpdate],
        "010RU", ["切换2秒提示", ToggleTimedTooltipDisplay],
    )
}

SetOperationModeActions(modeName, actions*) {
    global g_OperationModeActionMap
    global g_CurrentOperationMode := modeName
    actionsMap := Map()
    actionsMap.Set(actions*)
    g_OperationModeActionMap[g_CurrentOperationMode] := actionsMap
}

SetAndNotifyOperationMode(modeName, actions*) {
    SetOperationModeActions(modeName, actions*)
    ShowTemporaryTooltip("已切换到" g_CurrentOperationMode "模式")
}

SwitchToNormalOperationMode() {
    global g_CurrentOperationMode := "normal"
    ShowTemporaryTooltip("已恢复到normal模式")
}

PrepareAndShowRadialMenu() {
    CaptureWindowUnderCursorPos()
    ShowRadialMenuAtCursorPos()
    InitializeRadialMenuTooltip()
}

^!r:: {
    Reload
}

^!c:: {
    CompileMouseScriptAndRun()
}

^!t:: {
    ToggleOrRunOExe()
}

#HotIf not IsRemoteDesktopActiveOrRBtnPressed()

RButton:: {
    ResetAllMouseButtonStates()
    PrepareAndShowRadialMenu()
}

~LButton & RButton:: {
    Global g_LeftMouseButtonState := 1
    PrepareAndShowRadialMenu()
}

RButton Up:: {
    CleanupRadialMenuTooltip()
    HideRadialMenu()
    if (IsCursorWithinRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedRadialMenuAction()
    }
    ResetAllMouseButtonStates()
}

#HotIf

#HotIf g_CurrentOperationMode = "normal"

~LButton:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftMouseButtonState()
        return
    }
    MouseGetPos(&x)
    if (x >= 0 && x <= 10) {
        if (IsDoubleClickEvent()) {
            ToggleOrRunOExe()
        }
    }
}

~MButton:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleMouseButtonState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelMouseButtonState()
        return
    }
}

#HotIf

#Requires AutoHotkey v2.0

;;优化GetWindowsUnderCursorPos性能
;;彻底修复切换激活窗口导致任务栏图标闪烁的问题
;;避免误置顶窗口
;;已适配模式
;;滚动滚轮，所有窗口透明度设180，2秒后恢复原透明度
;;解决边移鼠标边滚滚轮不激活下一窗口问题

EnterWindowActivationMode() {
    SetAndNotifyOperationMode("window_activate",
        "000RU", ["切换最大化窗口", ToggleCapturedWindowMaximize],
        "000RD", ["最小化窗口", MinimizeCapturedWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleCapturedWindowTopmost],
        "000D", ["激活窗口", ActivateCapturedWindow],
        "000L", ["恢复普通模式", SwitchToNormalOperationMode],
        "000R", ["单击目标", ClickAtCapturedMousePos],
        "000LU", ["窗口控制模式2", EnterBasicWindowControlMode2],
    )
}

SwitchToTargetWindowInList(direction) {
    global g_TargetWindowList, g_CurrentWindowIndex, g_LastMousePos, g_LastActiveWindowHwnd
    global g_OriginalWindowTransparency, g_WindowOpacityRestoreTimer
    ResetWindowOpacityRestoreTimer()
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    if (Abs(mouseX - g_LastMousePos.x) > 10 || Abs(mouseY - g_LastMousePos.y) > 10) {
        RestoreAllWindowsOriginalOpacity()
        g_TargetWindowList := GetWindowsUnderCursorPos(mouseX, mouseY)
        g_CurrentWindowIndex := 0
        g_LastMousePos := {x: mouseX, y: mouseY}
        g_LastActiveWindowHwnd := 0
        SetTargetWindowsOpacity(g_TargetWindowActivateOpacity)
        if (g_TargetWindowList.Length > 0) {
            ShowTemporaryTooltip("找到 " g_TargetWindowList.Length " 个窗口")
        } else {
            ShowTemporaryTooltip("未找到符合条件的窗口")
        }
    }
    if (g_TargetWindowList.Length = 0)
        return
    if (g_CurrentWindowIndex = 0) {
        g_CurrentWindowIndex := 2
    } else {
        g_CurrentWindowIndex += direction
    }
    if (g_CurrentWindowIndex > g_TargetWindowList.Length)
        g_CurrentWindowIndex := 1
    else if (g_CurrentWindowIndex < 1)
        g_CurrentWindowIndex := g_TargetWindowList.Length
    try {
        hwnd := g_TargetWindowList[g_CurrentWindowIndex]
        if (hwnd = g_LastActiveWindowHwnd) {
            ShowTemporaryTooltip("窗口 " g_CurrentWindowIndex " / " g_TargetWindowList.Length " - " WinGetTitle("ahk_id " hwnd) " (已激活)")
            return
        }
        SwitchToTargetWindow(hwnd)
        g_LastActiveWindowHwnd := hwnd
        ShowTemporaryTooltip("窗口 " g_CurrentWindowIndex " / " g_TargetWindowList.Length " - " WinGetTitle("ahk_id " hwnd))
    }
}

SetTargetWindowsOpacity(opacity := 180) {
    global g_TargetWindowList, g_OriginalWindowTransparency
    for hwnd in g_TargetWindowList {
        if (!g_OriginalWindowTransparency.Has(hwnd)) {
            try {
                originalOpacity := WinGetTransparent("ahk_id " hwnd)
                g_OriginalWindowTransparency[hwnd] := originalOpacity = "" ? 255 : originalOpacity
            } catch {
                g_OriginalWindowTransparency[hwnd] := 255
            }
        }
        try {
            WinSetTransparent(opacity, "ahk_id " hwnd)
        }
    }
}

RestoreAllWindowsOriginalOpacity() {
    global g_OriginalWindowTransparency
    for hwnd, originalOpacity in g_OriginalWindowTransparency {
        try {
            WinSetTransparent(originalOpacity, "ahk_id " hwnd)
        }
    }
    g_OriginalWindowTransparency.Clear()
}

ResetWindowOpacityRestoreTimer() {
    global g_WindowOpacityRestoreTimer
    if (g_WindowOpacityRestoreTimer) {
        SetTimer(g_WindowOpacityRestoreTimer, 0)
    }
    g_WindowOpacityRestoreTimer := SetTimer(RestoreAllWindowsOriginalOpacity, -2000)
}

GetWindowsUnderCursorPos(mouseX, mouseY) {
    static lastMousePos := {x: 0, y: 0}
    static lastWindows := []
    static lastTimestamp := 0
    ResetWindowOpacityRestoreTimer()
    currentTime := A_TickCount
    if (Abs(mouseX - lastMousePos.x) <= 2 && Abs(mouseY - lastMousePos.y) <= 2 && currentTime - lastTimestamp < 500) {
        return lastWindows
    }
    windows := []
    allWindows := WinGetList()
    windows.Capacity := allWindows.Length
    for hwnd in allWindows {
        style := WinGetStyle("ahk_id " hwnd)
        if (!(style & 0x10000000))
            continue
        if (WinGetMinMax("ahk_id " hwnd) = -1)
            continue
        class := WinGetClass("ahk_id " hwnd)
        if (class = "Progman" || class = "WorkerW" || class = "Shell_TrayWnd" ||
            class = "Shell_SecondaryTrayWnd" || class = "NotifyIconOverflowWindow" ||
            class = "Windows.UI.Core.CoreWindow") {
            continue
        }
        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x80)
            continue
        title := WinGetTitle("ahk_id " hwnd)
        if (title = "")
            continue
        if (IsPointWithinWindowBounds(hwnd, mouseX, mouseY)) {
            windows.Push(hwnd)
        }
    }
    lastMousePos := {x: mouseX, y: mouseY}
    lastWindows := windows
    lastTimestamp := currentTime
    return windows
}

SwitchToTargetWindow(hwnd) {
    if (WinActive("ahk_id " hwnd)) {
        return
    }
    if (WinGetMinMax("ahk_id " hwnd) = -1) {
        WinRestore("ahk_id " hwnd)
    }
    SafelyActivateTargetWindow(hwnd)
}

SafelyActivateTargetWindow(hwnd) {
    SimulateAltTabToTargetWindow(hwnd)
    if (!WinActive("ahk_id " hwnd)) {
        try {
            DllCall("SetForegroundWindow", "ptr", hwnd)
        }
    }
}

SimulateAltTabToTargetWindow(hwnd) {
    originalHwnd := WinGetID("A")
    if (originalHwnd = hwnd) {
        return
    }
    Send("!{Esc}")
    WinWaitActive("ahk_id " hwnd, , 0.1)
    if (!WinActive("ahk_id " hwnd)) {
        WinActivate("ahk_id " hwnd)
    }
}

IsPointWithinWindowBounds(hwnd, x, y) {
    rect := Buffer(16, 0)
    if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rect)
        return false
    left := NumGet(rect, 0, "Int")
    top := NumGet(rect, 4, "Int")
    right := NumGet(rect, 8, "Int")
    bottom := NumGet(rect, 12, "Int")
    return (x >= left && x <= right && y >= top && y <= bottom)
}

#HotIf g_CurrentOperationMode = "window_activate"

WheelUp:: {
    SwitchToTargetWindowInList(-1)
}

WheelDown:: {
    SwitchToTargetWindowInList(1)
}

LButton:: {
    RestoreAllWindowsOriginalOpacity()
    SwitchToNormalOperationMode()
}

^Del:: {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    title := WinGetTitle("ahk_id " mouseWin)
    class := WinGetClass("ahk_id " mouseWin)
    style := WinGetStyle("ahk_id " mouseWin)
    exStyle := WinGetExStyle("ahk_id " mouseWin)
    info := "窗口信息：`n"
    info .= "标题: " title "`n"
    info .= "类名: " class "`n"
    info .= "样式: " Format("0x{:X}", style) "`n"
    info .= "扩展样式: " Format("0x{:X}", exStyle) "`n"
    info .= "鼠标位置: " mouseX ", " mouseY "`n"
    info .= "窗口ID: " mouseWin
    MsgBox(info)
}

^End:: {
    global g_TargetWindowList, g_CurrentWindowIndex, g_LastMousePos, g_LastActiveWindowHwnd
    MouseGetPos(&mouseX, &mouseY)
    g_TargetWindowList := GetWindowsUnderCursorPos(mouseX, mouseY)
    g_CurrentWindowIndex := 0
    g_LastMousePos := {x: mouseX, y: mouseY}
    g_LastActiveWindowHwnd := 0
    if (g_TargetWindowList.Length > 0) {
        ShowTemporaryTooltip("重新扫描完成，找到 " g_TargetWindowList.Length " 个窗口")
    } else {
        ShowTemporaryTooltip("重新扫描完成，未找到窗口")
    }
}

^PgDn:: {
    global g_TargetWindowList, g_CurrentWindowIndex
    if (g_TargetWindowList.Length = 0) {
        MsgBox("没有找到窗口")
        return
    }
    listText := "当前窗口列表：`n`n"
    for index, hwnd in g_TargetWindowList {
        title := WinGetTitle("ahk_id " hwnd)
        class := WinGetClass("ahk_id " hwnd)
        status := (index = g_CurrentWindowIndex) ? " ← 当前" : ""
        listText .= index ". " title " (" class ")" status "`n"
    }
    MsgBox(listText)
}

#HotIf

#Requires AutoHotkey v2.0

g_WindowsExemptFromWindowControl := [
    "ahk_class tooltips_class32",
]

EnterBasicWindowControlMode() {
    SetAndNotifyOperationMode("window_control",
        "000RU", ["切换最大化窗口", ToggleCapturedWindowMaximize],
        "000RD", ["最小化窗口", MinimizeCapturedWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleCapturedWindowTopmost],
        "000D", ["激活窗口", ActivateCapturedWindow],
        "000L", ["恢复普通模式", SwitchToNormalOperationMode],
        "000R", ["单击目标", ClickAtCapturedMousePos],
        "000LU", ["窗口控制模式2", EnterBasicWindowControlMode2],
        "100LU", ["窗口Kill模式", EnterWindowCloseKillMode],
    )
}

ProcessBasicWindowResizing() {
    global g_WindowResizeState
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessBasicWindowResizing, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeState.startMouseX
    deltaY := currentMouseY - g_WindowResizeState.startMouseY
    newX := g_WindowResizeState.startWinX
    newY := g_WindowResizeState.startWinY
    newWidth := g_WindowResizeState.startWinW
    newHeight := g_WindowResizeState.startWinH
    switch g_WindowResizeState.resizeEdge {
        case "top-left":
            newX := g_WindowResizeState.startWinX + deltaX
            newY := g_WindowResizeState.startWinY + deltaY
            newWidth := g_WindowResizeState.startWinW - deltaX
            newHeight := g_WindowResizeState.startWinH - deltaY
        case "top":
            newY := g_WindowResizeState.startWinY + deltaY
            newHeight := g_WindowResizeState.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeState.startWinY + deltaY
            newWidth := g_WindowResizeState.startWinW + deltaX
            newHeight := g_WindowResizeState.startWinH - deltaY
        case "left":
            newX := g_WindowResizeState.startWinX + deltaX
            newWidth := g_WindowResizeState.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeState.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeState.startWinX + deltaX
            newWidth := g_WindowResizeState.startWinW - deltaX
            newHeight := g_WindowResizeState.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeState.startWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_WindowResizeState.startWinW + deltaX
            newHeight := g_WindowResizeState.startWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeState.win
}

ProcessBasicWindowMovement() {
    global g_WindowMovementState
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessBasicWindowMovement, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMovementState.startMouseX
    deltaY := currentMouseY - g_WindowMovementState.startMouseY
    newX := g_WindowMovementState.startWinX + deltaX
    newY := g_WindowMovementState.startWinY + deltaY
    WinMove newX, newY, , , g_WindowMovementState.win
}

#HotIf g_CurrentOperationMode = "window_control"

LButton:: {
    global g_WindowMovementState
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMovementState.startMouseX := startMouseX
        g_WindowMovementState.startMouseY := startMouseY
        g_WindowMovementState.startWinX := startWinX
        g_WindowMovementState.startWinY := startWinY
        g_WindowMovementState.win := windowUnderCursor
        SetTimer ProcessBasicWindowMovement, 10
    }
}

LButton Up:: {
    SetTimer ProcessBasicWindowMovement, 0
}

MButton:: {
    global g_WindowResizeState
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, &startWinW, &startWinH, windowUnderCursor
        cursorXRelative := startMouseX - startWinX
        cursorYRelative := startMouseY - startWinY
        if (cursorXRelative < startWinW / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeState.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeState.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeState.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeState.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeState.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeState.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeState.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeState.resizeEdge := "bottom"
            } else {
                g_WindowResizeState.resizeEdge := "center"
            }
        }
        g_WindowResizeState.startMouseX := startMouseX
        g_WindowResizeState.startMouseY := startMouseY
        g_WindowResizeState.startWinX := startWinX
        g_WindowResizeState.startWinY := startWinY
        g_WindowResizeState.startWinW := startWinW
        g_WindowResizeState.startWinH := startWinH
        g_WindowResizeState.win := windowUnderCursor
        SetTimer ProcessBasicWindowResizing, 10
    }
}

MButton Up:: {
    SetTimer ProcessBasicWindowResizing, 0
}

WheelDown:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    DecreaseWindowOpacity(windowUnderCursor)
}

WheelUp:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    IncreaseWindowOpacity(windowUnderCursor)
}

#HotIf

#Requires AutoHotkey v2.0

EnterBasicWindowControlMode2() {
    SetAndNotifyOperationMode("window_control2",
        "000RU", ["切换最大化窗口", ToggleCapturedWindowMaximize],
        "000RD", ["最小化窗口", MinimizeCapturedWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleCapturedWindowTopmost],
        "000D", ["激活窗口", ActivateCapturedWindow],
        "000L", ["恢复普通模式", SwitchToNormalOperationMode],
        "000R", ["单击目标", ClickAtCapturedMousePos],
        "000LU", ["窗口控制模式", EnterBasicWindowControlMode],
        "100LU", ["窗口Kill模式", EnterWindowCloseKillMode],
    )
}

GetScreenWorkAreaBounds(winHwnd) {
    monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHwnd, "UInt", 0x2, "Ptr")
    if (monitorHandle = 0) {
        return {left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight}
    }
    monitorInfo := Buffer(40, 0)
    NumPut("UInt", 40, monitorInfo, 0)
    if (DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)) {
        workLeft := NumGet(monitorInfo, 20, "Int")
        workTop := NumGet(monitorInfo, 24, "Int")
        workRight := NumGet(monitorInfo, 28, "Int")
        workBottom := NumGet(monitorInfo, 32, "Int")
        return {left: workLeft, top: workTop, right: workRight, bottom: workBottom}
    }
    return {left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight}
}

ProcessBasicWindowResizing2() {
    global g_WindowResizeState, g_CurrentOperationMode
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessBasicWindowResizing2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeState.startMouseX
    deltaY := currentMouseY - g_WindowResizeState.startMouseY
    workArea := GetScreenWorkAreaBounds(g_WindowResizeState.win)
    newX := g_WindowResizeState.startWinX
    newY := g_WindowResizeState.startWinY
    newWidth := g_WindowResizeState.startWinW
    newHeight := g_WindowResizeState.startWinH
    switch g_WindowResizeState.resizeEdge {
        case "top-left":
            newX := g_WindowResizeState.startWinX + deltaX
            newY := g_WindowResizeState.startWinY + deltaY
            newWidth := g_WindowResizeState.startWinW - deltaX
            newHeight := g_WindowResizeState.startWinH - deltaY
        case "top":
            newY := g_WindowResizeState.startWinY + deltaY
            newHeight := g_WindowResizeState.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeState.startWinY + deltaY
            newWidth := g_WindowResizeState.startWinW + deltaX
            newHeight := g_WindowResizeState.startWinH - deltaY
        case "left":
            newX := g_WindowResizeState.startWinX + deltaX
            newWidth := g_WindowResizeState.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeState.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeState.startWinX + deltaX
            newWidth := g_WindowResizeState.startWinW - deltaX
            newHeight := g_WindowResizeState.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeState.startWinH + deltaY
        case "bottom-right":
            newWidth := g_WindowResizeState.startWinW + deltaX
            newHeight := g_WindowResizeState.startWinH + deltaY
        case "center":
            newX := g_WindowResizeState.startWinX + deltaX / 2
            newY := g_WindowResizeState.startWinY + deltaY / 2
            newWidth := g_WindowResizeState.startWinW + deltaX
            newHeight := g_WindowResizeState.startWinH + deltaY
    }
    if (newWidth < 100) {
        newWidth := 100
    }
    if (newHeight < 100) {
        newHeight := 100
    }
    if (newX < workArea.left) {
        newX := workArea.left
        if (g_WindowResizeState.resizeEdge = "left" || g_WindowResizeState.resizeEdge = "top-left" || g_WindowResizeState.resizeEdge = "bottom-left") {
            newWidth := g_WindowResizeState.startWinW - (currentMouseX - g_WindowResizeState.startMouseX)
            if (newWidth < 100) {
                newWidth := 100
            }
        }
    }
    if (newY < workArea.top) {
        newY := workArea.top
        if (g_WindowResizeState.resizeEdge = "top" || g_WindowResizeState.resizeEdge = "top-left" || g_WindowResizeState.resizeEdge = "top-right") {
            newHeight := g_WindowResizeState.startWinH - (currentMouseY - g_WindowResizeState.startMouseY)
            if (newHeight < 100) {
                newHeight := 100
            }
        }
    }
    if (newX + newWidth > workArea.right) {
        newX := workArea.right - newWidth
        if (newX < workArea.left) {
            newX := workArea.left
            newWidth := workArea.right - workArea.left
        }
    }
    if (newY + newHeight > workArea.bottom) {
        newY := workArea.bottom - newHeight
        if (newY < workArea.top) {
            newY := workArea.top
            newHeight := workArea.bottom - workArea.top
        }
    }
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeState.win
}

ProcessBasicWindowMovement2() {
    global g_WindowMovementState, g_CurrentOperationMode
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessBasicWindowMovement2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMovementState.startMouseX
    deltaY := currentMouseY - g_WindowMovementState.startMouseY
    newX := g_WindowMovementState.startWinX + deltaX
    newY := g_WindowMovementState.startWinY + deltaY
    workArea := GetScreenWorkAreaBounds(g_WindowMovementState.win)
    WinGetPos , , &winWidth, &winHeight, g_WindowMovementState.win
    if (winWidth > workArea.right - workArea.left || winHeight > workArea.bottom - workArea.top) {
        originalAspectRatio := winWidth / winHeight
        maxWidth := workArea.right - workArea.left
        maxHeight := workArea.bottom - workArea.top
        if (maxWidth / maxHeight > originalAspectRatio) {
            newHeight := maxHeight
            newWidth := Round(newHeight * originalAspectRatio)
        } else {
            newWidth := maxWidth
            newHeight := Round(newWidth / originalAspectRatio)
        }
        if (newWidth < 100)
            newWidth := 100
        if (newHeight < 100)
            newHeight := 100
        winWidth := newWidth
        winHeight := newHeight
        if (newX < workArea.left)
            newX := workArea.left
        if (newY < workArea.top)
            newY := workArea.top
        if (newX + winWidth > workArea.right)
            newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom)
            newY := workArea.bottom - winHeight
        WinMove newX, newY, winWidth, winHeight, g_WindowMovementState.win
    } else {
        if (newX < workArea.left)
            newX := workArea.left
        if (newY < workArea.top)
            newY := workArea.top
        if (newX + winWidth > workArea.right)
            newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom)
            newY := workArea.bottom - winHeight
        WinMove newX, newY, , , g_WindowMovementState.win
    }
    g_WindowMovementState.startMouseX := currentMouseX
    g_WindowMovementState.startMouseY := currentMouseY
    g_WindowMovementState.startWinX := newX
    g_WindowMovementState.startWinY := newY
}

#HotIf g_CurrentOperationMode = "window_control2"

LButton:: {
    global g_WindowMovementState
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMovementState.startMouseX := startMouseX
        g_WindowMovementState.startMouseY := startMouseY
        g_WindowMovementState.startWinX := startWinX
        g_WindowMovementState.startWinY := startWinY
        g_WindowMovementState.win := windowUnderCursor
        SetTimer ProcessBasicWindowMovement2, 10
    }
}

LButton Up:: {
    SetTimer ProcessBasicWindowMovement2, 0
}

MButton:: {
    global g_WindowResizeState
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, &startWinW, &startWinH, windowUnderCursor
        cursorXRelative := startMouseX - startWinX
        cursorYRelative := startMouseY - startWinY
        if (cursorXRelative < startWinW / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeState.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeState.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeState.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeState.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeState.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeState.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeState.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeState.resizeEdge := "bottom"
            } else {
                g_WindowResizeState.resizeEdge := "center"
            }
        }
        g_WindowResizeState.startMouseX := startMouseX
        g_WindowResizeState.startMouseY := startMouseY
        g_WindowResizeState.startWinX := startWinX
        g_WindowResizeState.startWinY := startWinY
        g_WindowResizeState.startWinW := startWinW
        g_WindowResizeState.startWinH := startWinH
        g_WindowResizeState.win := windowUnderCursor
        SetTimer ProcessBasicWindowResizing2, 10
    }
}

MButton Up:: {
    SetTimer ProcessBasicWindowResizing2, 0
}

WheelDown:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        currentTransparency := WinGetTransparent(windowUnderCursor)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency - 15
        if (newTransparency < 30)
            newTransparency := 30
        WinSetTransparent newTransparency, windowUnderCursor
        ShowTemporaryTooltip("透明度: " newTransparency)
    }
}

WheelUp:: {
    if (IsCursorWithinRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelMouseButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsExemptFromWindowControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        currentTransparency := WinGetTransparent(windowUnderCursor)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency + 15
        if (newTransparency > 255)
            newTransparency := 255
        WinSetTransparent newTransparency, windowUnderCursor
        ShowTemporaryTooltip("透明度: " newTransparency)
    }
}

#HotIf

#Requires AutoHotkey v2.0

g_WindowsExemptFromCloseAndKill := [
    "ahk_exe explorer.exe",
]

EnterWindowCloseKillMode() {
    SetAndNotifyOperationMode("window_kill",
        "000RU", ["切换最大化窗口", ToggleCapturedWindowMaximize],
        "000RD", ["最小化窗口", MinimizeCapturedWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleCapturedWindowTopmost],
        "000D", ["激活窗口", ActivateCapturedWindow],
        "000L", ["恢复普通模式", SwitchToNormalOperationMode],
        "000R", ["单击目标", ClickAtCapturedMousePos],
        "000LU", ["窗口控制模式2", EnterBasicWindowControlMode2],
    )
}

#HotIf g_CurrentOperationMode = "window_kill"

LButton:: {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        for _, winTitle in g_WindowsExemptFromCloseAndKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                if TryActivateWindow(windowUnderCursor) {
                    Send("^w")
                }
                return
            }
        }
        if TryActivateWindow(windowUnderCursor) {
            WinClose(windowUnderCursor) ;;Send("!{F4}")有些窗口不顶用
        }
    }
}

MButton:: {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        for _, winTitle in g_WindowsExemptFromCloseAndKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                return
            }
        }
        winPID := WinGetPID(windowUnderCursor)
        RunCommandSilently("taskkill /f /pid " winPID)
    }
}

#HotIf
