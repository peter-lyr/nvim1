#Requires AutoHotkey v2.0

global fileServExe := "ahk_exe Fileserv.exe"
global fileServActiveWin := 0

global g_PreviousTooltip := ""
global g_UpdateRadialMenuTooltipEn := 1
global g_ShowTimedTooltipEn := 1

global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}

global g_CurrentMode := "normal"

global g_WindowList := []
global g_CurrentIndex := 0
global g_LastMousePos := {x: 0, y: 0}
global g_LastActiveHwnd := 0
global g_OriginalTransparency := Map()
global g_ActivateTransparency := 180
global g_OpacityTimer := 0

global g_RadialMenuGui := ""
global g_RadialMenuGuiHwnd := 0
global g_RadialMenuRadius := 5
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_TargetWindowHwnd := 0
global g_TargetClickPosX := 0
global g_TargetClickPosY := 0

global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1

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

global g_ModeActionMappings := Map()

InitializeNormalModeActions()
DisplayRadialMenuAtCursor()
HideRadialMenu()

^Ins::ExitApp

#Requires AutoHotkey v2.0

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

#Requires AutoHotkey v2.0

CreateRadialMenuGui(centerX, centerY, width, height, transparency, backgroundColor) {
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

DisplayRadialMenuAtCursor() {
    global g_RadialMenuGui, g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    g_RadialMenuCenterX := cursorX
    g_RadialMenuCenterY := cursorY
    menuDiameter := g_RadialMenuRadius * 2
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        menuX := cursorX - g_RadialMenuRadius
        menuY := cursorY - g_RadialMenuRadius
        g_RadialMenuGui.Show("x" menuX " y" menuY " w" menuDiameter " h" menuDiameter " NoActivate")
        g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
    } else {
        try {
            g_RadialMenuGui := CreateRadialMenuGui(cursorX, cursorY, menuDiameter, menuDiameter, 180, "FF0000")
            g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
        }
        catch as e {
            ShowTimedTooltip("创建圆形菜单失败: " . e.Message)
            g_RadialMenuGui := ""
            g_RadialMenuGuiHwnd := 0
        }
    }
}

HideRadialMenu() {
    global g_RadialMenuGui
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        g_RadialMenuGui.Hide()
    }
}

IsCursorInsideRadialMenu() {
    global g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    if (!g_RadialMenuGuiHwnd)
        return false
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    distanceFromCenter := Sqrt((cursorX - g_RadialMenuCenterX)**2 + (cursorY - g_RadialMenuCenterY)**2)
    return distanceFromCenter <= g_RadialMenuRadius
}

CalculateCursorDirection() {
    global g_RadialMenuCenterX, g_RadialMenuCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    deltaX := cursorX - g_RadialMenuCenterX
    deltaY := cursorY - g_RadialMenuCenterY
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

GetDirectionChineseName(directionCode) {
    global g_DirectionNames
    return g_DirectionNames.Has(directionCode) ? g_DirectionNames[directionCode] : directionCode
}

GetDirectionSymbol(directionCode) {
    global g_DirectionSymbols
    return g_DirectionSymbols.Has(directionCode) ? g_DirectionSymbols[directionCode] : "•"
}

GetCurrentButtonStateAndDirection() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    direction := CalculateCursorDirection()
    return g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" direction
}

GetCurrentModeActionMap() {
    global g_ModeActionMappings, g_CurrentMode
    if (!g_ModeActionMappings.Has(g_CurrentMode)) {
        return g_ModeActionMappings["normal"]
    }
    return g_ModeActionMappings[g_CurrentMode]
}

GenerateRadialMenuDisplay() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    actionMap := GetCurrentModeActionMap()
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
            stateKey := g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" directionCode
            actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
            actionDescription := actionInfo[1]
            directionSymbol := GetDirectionSymbol(directionCode)
            directionName := GetDirectionChineseName(directionCode)
            displayText := directionSymbol " " directionName ":" actionDescription
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }
    displayText := "模式: " g_CurrentMode " 状态: 左键=" g_LeftButtonState ", 中键=" g_MiddleButtonState ", 滚轮=" g_WheelButtonState "`n`n"
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

GenerateCurrentDirectionInfo() {
    directionCode := CalculateCursorDirection()
    directionSymbol := GetDirectionSymbol(directionCode)
    directionName := GetDirectionChineseName(directionCode)
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
    actionDescription := actionInfo[1]
    return "模式: " g_CurrentMode " 方向: " directionSymbol " " directionName "`n操作: " actionDescription
}

CycleLeftButtonState() {
    global g_LeftButtonState, g_MaxLeftButtonStates
    g_LeftButtonState := Mod(g_LeftButtonState + 1, g_MaxLeftButtonStates + 1)
}

CycleMiddleButtonState() {
    global g_MiddleButtonState, g_MaxMiddleButtonStates
    g_MiddleButtonState := Mod(g_MiddleButtonState + 1, g_MaxMiddleButtonStates + 1)
}

CycleWheelButtonState() {
    global g_WheelButtonState, g_MaxWheelButtonStates
    g_WheelButtonState := Mod(g_WheelButtonState + 1, g_MaxWheelButtonStates + 1)
}

CaptureWindowUnderCursor() {
    global g_TargetClickPosX, g_TargetClickPosY, g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(&g_TargetClickPosX, &g_TargetClickPosY, &g_TargetWindowHwnd)
}

ResetButtonStates() {
    global g_LeftButtonState := 0
    global g_MiddleButtonState := 0
    global g_WheelButtonState := 0
}

ExecuteSelectedAction() {
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    if (actionMap.Has(stateKey)) {
        actionInfo := actionMap[stateKey]
        actionFunction := actionInfo[2]
        try {
            actionFunction()
        } catch as e {
            ShowTimedTooltip("执行操作时出错: " e.Message " [" actionInfo[1] "]")
        }
    } else {
        ShowTimedTooltip("未定义的操作: " stateKey)
    }
}

#Requires AutoHotkey v2.0

ToggleUpdateRadialMenuTooltipEn() {
    global g_UpdateRadialMenuTooltipEn
    g_UpdateRadialMenuTooltipEn := 1 -g_UpdateRadialMenuTooltipEn
}

ToggleShowTimedTooltipEn() {
    global g_ShowTimedTooltipEn
    g_ShowTimedTooltipEn := 1 -g_ShowTimedTooltipEn
}

ShowTimedTooltip(message, timeout := 2000) {
    global g_ShowTimedTooltipEn
    if not g_ShowTimedTooltipEn {
        return
    }
    ToolTip(message)
    SetTimer(() => ToolTip(), -timeout)
}

UpdateRadialMenuTooltip() {
    global g_PreviousTooltip
    global g_UpdateRadialMenuTooltipEn
    if not g_UpdateRadialMenuTooltipEn {
        return
    }
    if (IsCursorInsideRadialMenu()) {
        newContent := GenerateRadialMenuDisplay()
    } else {
        newContent := GenerateCurrentDirectionInfo()
    }
    if (newContent != g_PreviousTooltip) {
        ToolTip(newContent)
        g_PreviousTooltip := newContent
    }
}

InitRadialMenuTooltip() {
    global g_PreviousTooltip := ""
    SetTimer(UpdateRadialMenuTooltip, 10)
}

ExitRadialMenuTooltip() {
    ToolTip()
    SetTimer(UpdateRadialMenuTooltip, 0)
    global g_PreviousTooltip := ""
}

#Requires AutoHotkey v2.0

remote_desktop_exes := [
    "ahk_exe mstsc.exe",
]

remote_desktop_classes := [
    "ahk_class TscShellContainerClass",
]

remote_desktop_titles := [
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

#Requires AutoHotkey v2.0

MyWinActivate(winTitle) {
    WinWaitActive(winTitle, , 0.1)
    if (!WinActive(winTitle)) {
        WinActivate(winTitle)
    }
    if (WinActive(winTitle)) {
        return true
    }
    return false
}

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
                if (ActivateExisted("ahk_id " filteredList[1])) {
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
                if (ActivateExisted("ahk_id " filteredList[nextIndex + 1])) {
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
            if (ActivateExisted("ahk_id " windowList[1])) {
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

RestoreClipboard(ClipboardOld) {
    A_Clipboard := ClipboardOld
    ClipboardOld := ""
    Sleep(50)
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
                RunInWinR(windowTitle, appPath)
            } else if (filteredList.Length = 1) {
                if (ActivateExisted("ahk_id " filteredList[1])) {
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
                if (ActivateExisted("ahk_id " filteredList[nextIndex + 1])) {
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
            if (ActivateExisted("ahk_id " windowList[1])) {
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
        RunInWinR(windowTitle, appPath)
    }
    return false
}

#Requires AutoHotkey v2.0

;;桌面不透明化
g_WindowsNoTransparencyControl := [
    "ahk_class tooltips_class32",
    GetDesktopClass(),
]

GetDesktopClass() {
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

ActivateTargetWindow() {
    global g_TargetWindowHwnd
    WinActivate(g_TargetWindowHwnd)
}

ToggleTargetWindowTopmost(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if (hwnd) {
        currentStyle := WinGetExStyle(hwnd)
        isTopmost := (currentStyle & 0x8)
        if (isTopmost) {
            WinSetAlwaysOnTop false, hwnd
            ShowTimedTooltip("取消窗口置顶")
        } else {
            WinSetAlwaysOnTop true, hwnd
            ShowTimedTooltip("窗口已置顶")
        }
    } else {
        ShowTimedTooltip("没有找到目标窗口")
    }
}

MinimizeTargetWindow(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if WinExist(hwnd) = WinExist(GetDesktopClass()) {
        return ;;桌面不最小化
    }
    WinMinimize(hwnd)
}

ToggleTargetWindowMaximize(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if (WinGetMinMax(hwnd) = 1) {
        WinRestore(hwnd)
    } else {
        WinMaximize(hwnd)
    }
}

ClickAtTargetPosition() {
    global g_TargetClickPosX, g_TargetClickPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickPosX, g_TargetClickPosY, "Left")
    MouseMove(originalX, originalY, 0)
}

TransparencyDown(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    for _, winTitle in g_WindowsNoTransparencyControl {
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
    ShowTimedTooltip("透明度: " newTransparency)
}

TransparencyUp(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    for _, winTitle in g_WindowsNoTransparencyControl {
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
    ShowTimedTooltip("透明度: " newTransparency)
}

#Requires AutoHotkey v2.0

^#k:: {
    ToggleTargetWindowMaximize("A")
}

^#j:: {
    MinimizeTargetWindow("A")
}

^#m:: {
    ToggleTargetWindowTopmost("A")
}

^#h:: {
    TransparencyDown("A")
}

^#l:: {
    TransparencyUp("A")
}

#Requires AutoHotkey v2.0

g_MenuMode := false
g_CurrentMenu := "normal"
g_LastAltPress := 0
g_DoubleClickTime := 300
g_MenuTimer := 0
g_Timeout := 8000

MenuDefinitions := Map(
    "normal", Map(
        "q", ["打开企业微信", ActivateWXWorkExe, false],
        ",", ["打开或激活nvim-0.10.4", ActivateOrRunInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), true],
        ".", ["打开或激活nvim-0.11.4", ActivateOrRun.Bind("ahk_exe nvim-qt.exe", "nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), true],
        "/", ["激活mstsc", ActivateExisted.Bind("ahk_exe mstsc.exe"), false],
        "f", ["fileserv", SwitchMenu.Bind("fileserv"), true],
        "a", ["activate", SwitchMenu.Bind("activate"), true],
        "r", ["run", SwitchMenu.Bind("run"), true],
    ),
    "fileserv", Map(
        "f", ["打开或激活fileserv", ActivateFileserv, false],
        "k", ["CloseFileserv", CloseFileserv, false],
        "r", ["RestartFileserv", RestartFileserv, false],
        "u", ["FileServUpClip", FileServUpClip, false],
        "n", ["normal", SwitchMenu.Bind("normal"), true],
    ),
    "activate", Map(
        ",", ["打开或激活nvim-0.10.4", ActivateOrRunInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), true],
        ".", ["打开或激活nvim-0.11.4", ActivateOrRun.Bind("ahk_exe nvim-qt.exe", "nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), true],
        "/", ["激活mstsc", ActivateExisted.Bind("ahk_exe mstsc.exe"), false],
        "n", ["normal", SwitchMenu.Bind("normal"), true],
    ),
    "run", Map(
        ",", ["打开nvim-0.10.4", RunInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), false],
        ".", ["打开nvim-0.11.4", Run.Bind("nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), false],
        "n", ["normal", SwitchMenu.Bind("normal"), true],
    ),
)

~LAlt:: {
    global g_MenuMode, g_LastAltPress, g_DoubleClickTime
    currentTime := A_TickCount
    if (currentTime - g_LastAltPress < g_DoubleClickTime && !g_MenuMode) {
        JumpOutSideOffMsTsc()
        EnterMenuMode("normal")
    }
    g_LastAltPress := currentTime
}

EnterMenuMode(menuType) {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, g_Timeout, MenuDefinitions
    if (g_MenuMode) {
        return
    }
    g_MenuMode := true
    g_CurrentMenu := menuType
    if (MenuDefinitions.Has(menuType)) {
        ShowMenuTooltip(MenuDefinitions[menuType], menuType . "菜单")
    } else {
        ShowMenuTooltip(Map(), "未知菜单")
    }
    RegisterMenuHotkeys(menuType)
    Hotkey("Escape", ExitMenuMode, "On")
    g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
}

ExitMenuMode(*) {
    global g_MenuMode, g_MenuTimer
    if (!g_MenuMode) {
        return
    }
    g_MenuMode := false
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    UnregisterAllMenuHotkeys()
    ToolTip()
    Hotkey("Escape", "Off")
}

RegisterMenuHotkeys(menuType) {
    global MenuDefinitions
    if (MenuDefinitions.Has(menuType)) {
        for key, value in MenuDefinitions[menuType] {
            Hotkey(key, HandleMenuHotkey.Bind(key, menuType), "On")
        }
    }
}

UnregisterAllMenuHotkeys() {
    global MenuDefinitions
    for menuName, hotkeyMap in MenuDefinitions {
        for key in hotkeyMap {
            try Hotkey(key, "Off")
        }
    }
}

ShowMenuTooltip(hotkeyMap, menuName) {
    global g_Timeout
    tooltipText := menuName . "（" . g_Timeout//1000 . "秒后自动退出，按ESC立即退出）`n"
    for key, value in hotkeyMap {
        tooltipText .= "[" key "] " value[1]
        if (value[3]) {
            tooltipText .= " (维持菜单)"
        }
        tooltipText .= "`n"
    }
    ToolTip(tooltipText)
}

HandleMenuHotkey(key, menuType, *) {
    global g_CurrentMenu, g_MenuTimer, g_Timeout, MenuDefinitions
    if (g_CurrentMenu != menuType) {
        return
    }
    if (MenuDefinitions.Has(menuType) && MenuDefinitions[menuType].Has(key)) {
        action := MenuDefinitions[menuType][key][2]
        action.Call()
        if (!MenuDefinitions[menuType][key][3]) {
            ExitMenuMode()
        } else {
            if (g_MenuTimer) {
                SetTimer(g_MenuTimer, 0)
            }
            g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
        }
    }
}

SwitchMenu(targetMenu) {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, MenuDefinitions
    if (!g_MenuMode || g_CurrentMenu = targetMenu || !MenuDefinitions.Has(targetMenu)) {
        return
    }
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    g_MenuMode := false
    EnterMenuMode(targetMenu)
}

OnExit((*) => ExitMenuMode())

#Requires AutoHotkey v2.0

InitializeNormalModeActions() {
    ModeActionsSetDo("normal",
        ;;以下3个最常用
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        ;;各种模式
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
        "000U", ["窗口激活模式", EnterWindowActivateMode],
        ;;待替换
        "000D", ["向下移动光标", Send.Bind("{Down}")],
        "000L", ["向左移动光标", Send.Bind("{Left}")],
        "000R", ["向右移动光标", Send.Bind("{Right}")],
        ;;配置
        "010R", ["切换菜单提示", ToggleUpdateRadialMenuTooltipEn],
        "010RU", ["切换2秒提示", ToggleShowTimedTooltipEn],
    )
}

ModeActionsSetDo(modeName, actions*) {
    global g_ModeActionMappings
    global g_CurrentMode := modeName
    actionsMap := Map()
    actionsMap.Set(actions*)
    g_ModeActionMappings[g_CurrentMode] := actionsMap
}

ModeActionsSet(modeName, actions*) {
    ModeActionsSetDo(modeName, actions*)
    ShowTimedTooltip("已切换到" g_CurrentMode "模式")
}

EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复到normal模式")
}

RButtonDo() {
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    InitRadialMenuTooltip()
}

^!r:: {
    Reload
}

^!c:: {
    CompileMouseAndRun()
}

^!t:: {
    ToggleToOExe()
}

#HotIf not RemoteDesktopActiveOrRButtonPressed()

RButton:: {
    ResetButtonStates()
    RButtonDo()
}

~LButton & RButton:: {
    Global g_LeftButtonState := 1
    RButtonDo()
}

RButton Up:: {
    ExitRadialMenuTooltip()
    HideRadialMenu()
    if (IsCursorInsideRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedAction()
    }
    ResetButtonStates()
}

#HotIf

#HotIf g_CurrentMode = "normal"

~LButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    MouseGetPos(&x)
    if (x >= 0 && x <= 10) {
        if (IsDoubleClick()) {
            ToggleToOExe()
        }
    }
}

~MButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
}

#HotIf

#Requires AutoHotkey v2.0

;;优化GetWindowsAtMousePos性能
;;彻底修复切换激活窗口导致任务栏图标闪烁的问题
;;避免误置顶窗口
;;已适配模式
;;滚动滚轮，所有窗口透明度设180，2秒后恢复原透明度
;;解决边移鼠标边滚滚轮不激活下一窗口问题

EnterWindowActivateMode() {
    ModeActionsSet("window_activate",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
    )
}

SwitchWindow(direction) {
    global g_WindowList, g_CurrentIndex, g_LastMousePos, g_LastActiveHwnd
    global g_OriginalTransparency, g_OpacityTimer
    ResetOpacityTimer()
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    if (Abs(mouseX - g_LastMousePos.x) > 10 || Abs(mouseY - g_LastMousePos.y) > 10) {
        RestoreAllWindowsOpacity()
        g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
        g_CurrentIndex := 0
        g_LastMousePos := {x: mouseX, y: mouseY}
        g_LastActiveHwnd := 0
        SetWindowsOpacity(g_ActivateTransparency)
        if (g_WindowList.Length > 0) {
            ShowTimedTooltip("找到 " g_WindowList.Length " 个窗口")
        } else {
            ShowTimedTooltip("未找到符合条件的窗口")
        }
    }
    if (g_WindowList.Length = 0)
        return
    if (g_CurrentIndex = 0) {
        g_CurrentIndex := 2
    } else {
        g_CurrentIndex += direction
    }
    if (g_CurrentIndex > g_WindowList.Length)
        g_CurrentIndex := 1
    else if (g_CurrentIndex < 1)
        g_CurrentIndex := g_WindowList.Length
    try {
        hwnd := g_WindowList[g_CurrentIndex]
        if (hwnd = g_LastActiveHwnd) {
            ShowTimedTooltip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd) " (已激活)")
            return
        }
        SwitchToWindow(hwnd)
        g_LastActiveHwnd := hwnd
        ShowTimedTooltip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd))
    }
}

SetWindowsOpacity(opacity := 180) {
    global g_WindowList, g_OriginalTransparency
    for hwnd in g_WindowList {
        if (!g_OriginalTransparency.Has(hwnd)) {
            try {
                originalOpacity := WinGetTransparent("ahk_id " hwnd)
                g_OriginalTransparency[hwnd] := originalOpacity = "" ? 255 : originalOpacity
            } catch {
                g_OriginalTransparency[hwnd] := 255
            }
        }
        try {
            WinSetTransparent(opacity, "ahk_id " hwnd)
        }
    }
}

RestoreAllWindowsOpacity() {
    global g_OriginalTransparency
    for hwnd, originalOpacity in g_OriginalTransparency {
        try {
            WinSetTransparent(originalOpacity, "ahk_id " hwnd)
        }
    }
    g_OriginalTransparency.Clear()
}

ResetOpacityTimer() {
    global g_OpacityTimer
    if (g_OpacityTimer) {
        SetTimer(g_OpacityTimer, 0)
    }
    g_OpacityTimer := SetTimer(RestoreAllWindowsOpacity, -2000)
}

GetWindowsAtMousePos(mouseX, mouseY) {
    static lastMousePos := {x: 0, y: 0}
    static lastWindows := []
    static lastTimestamp := 0
    ResetOpacityTimer()
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
        if (IsPointInWindowOptimized(hwnd, mouseX, mouseY)) {
            windows.Push(hwnd)
        }
    }
    lastMousePos := {x: mouseX, y: mouseY}
    lastWindows := windows
    lastTimestamp := currentTime
    return windows
}

SwitchToWindow(hwnd) {
    if (WinActive("ahk_id " hwnd)) {
        return
    }
    if (WinGetMinMax("ahk_id " hwnd) = -1) {
        WinRestore("ahk_id " hwnd)
    }
    ActivateWindowSafely(hwnd)
}

ActivateWindowSafely(hwnd) {
    SimulateAltTab(hwnd)
    if (!WinActive("ahk_id " hwnd)) {
        try {
            DllCall("SetForegroundWindow", "ptr", hwnd)
        }
    }
}

SimulateAltTab(hwnd) {
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

IsPointInWindowOptimized(hwnd, x, y) {
    rect := Buffer(16, 0)
    if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rect)
        return false
    left := NumGet(rect, 0, "Int")
    top := NumGet(rect, 4, "Int")
    right := NumGet(rect, 8, "Int")
    bottom := NumGet(rect, 12, "Int")
    return (x >= left && x <= right && y >= top && y <= bottom)
}

#HotIf g_CurrentMode = "window_activate"

WheelUp:: {
    SwitchWindow(-1)
}

WheelDown:: {
    SwitchWindow(1)
}

LButton:: {
    RestoreAllWindowsOpacity()
    EnterNormalMode()
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
    global g_WindowList, g_CurrentIndex, g_LastMousePos, g_LastActiveHwnd
    MouseGetPos(&mouseX, &mouseY)
    g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
    g_CurrentIndex := 0
    g_LastMousePos := {x: mouseX, y: mouseY}
    g_LastActiveHwnd := 0
    if (g_WindowList.Length > 0) {
        ShowTimedTooltip("重新扫描完成，找到 " g_WindowList.Length " 个窗口")
    } else {
        ShowTimedTooltip("重新扫描完成，未找到窗口")
    }
}

^PgDn:: {
    global g_WindowList, g_CurrentIndex
    if (g_WindowList.Length = 0) {
        MsgBox("没有找到窗口")
        return
    }
    listText := "当前窗口列表：`n`n"
    for index, hwnd in g_WindowList {
        title := WinGetTitle("ahk_id " hwnd)
        class := WinGetClass("ahk_id " hwnd)
        status := (index = g_CurrentIndex) ? " ← 当前" : ""
        listText .= index ". " title " (" class ")" status "`n"
    }
    MsgBox(listText)
}

#HotIf

#Requires AutoHotkey v2.0

g_WindowsNoControl := [
    "ahk_class tooltips_class32",
]

EnterWindowControlMode() {
    ModeActionsSet("window_control",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
        "100LU", ["窗口Kill模式", EnterWindowKillMode],
    )
}

ProcessWindowResizing() {
    global g_WindowResizeInfo
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessWindowResizing, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeInfo.startMouseX
    deltaY := currentMouseY - g_WindowResizeInfo.startMouseY
    newX := g_WindowResizeInfo.startWinX
    newY := g_WindowResizeInfo.startWinY
    newWidth := g_WindowResizeInfo.startWinW
    newHeight := g_WindowResizeInfo.startWinH
    switch g_WindowResizeInfo.resizeEdge {
        case "top-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeInfo.win
}

ProcessWindowMovement() {
    global g_WindowMoveInfo
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessWindowMovement, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveInfo.startMouseX
    deltaY := currentMouseY - g_WindowMoveInfo.startMouseY
    newX := g_WindowMoveInfo.startWinX + deltaX
    newY := g_WindowMoveInfo.startWinY + deltaY
    WinMove newX, newY, , , g_WindowMoveInfo.win
}

#HotIf g_CurrentMode = "window_control"

LButton:: {
    global g_WindowMoveInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMoveInfo.startMouseX := startMouseX
        g_WindowMoveInfo.startMouseY := startMouseY
        g_WindowMoveInfo.startWinX := startWinX
        g_WindowMoveInfo.startWinY := startWinY
        g_WindowMoveInfo.win := windowUnderCursor
        SetTimer ProcessWindowMovement, 10
    }
}

LButton Up:: {
    SetTimer ProcessWindowMovement, 0
}

MButton:: {
    global g_WindowResizeInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
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
                g_WindowResizeInfo.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeInfo.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeInfo.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom"
            } else {
                g_WindowResizeInfo.resizeEdge := "center"
            }
        }
        g_WindowResizeInfo.startMouseX := startMouseX
        g_WindowResizeInfo.startMouseY := startMouseY
        g_WindowResizeInfo.startWinX := startWinX
        g_WindowResizeInfo.startWinY := startWinY
        g_WindowResizeInfo.startWinW := startWinW
        g_WindowResizeInfo.startWinH := startWinH
        g_WindowResizeInfo.win := windowUnderCursor
        SetTimer ProcessWindowResizing, 10
    }
}

MButton Up:: {
    SetTimer ProcessWindowResizing, 0
}

WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    TransparencyDown(windowUnderCursor)
}

WheelUp:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    TransparencyUp(windowUnderCursor)
}

#HotIf

#Requires AutoHotkey v2.0

EnterWindowControlMode2() {
    ModeActionsSet("window_control2",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式", EnterWindowControlMode],
        "100LU", ["窗口Kill模式", EnterWindowKillMode],
    )
}

GetScreenWorkArea(winHwnd) {
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

ProcessWindowResizing2() {
    global g_WindowResizeInfo, g_CurrentMode
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessWindowResizing2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeInfo.startMouseX
    deltaY := currentMouseY - g_WindowResizeInfo.startMouseY
    workArea := GetScreenWorkArea(g_WindowResizeInfo.win)
    newX := g_WindowResizeInfo.startWinX
    newY := g_WindowResizeInfo.startWinY
    newWidth := g_WindowResizeInfo.startWinW
    newHeight := g_WindowResizeInfo.startWinH
    switch g_WindowResizeInfo.resizeEdge {
        case "top-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom-right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "center":
            newX := g_WindowResizeInfo.startWinX + deltaX / 2
            newY := g_WindowResizeInfo.startWinY + deltaY / 2
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
    }
    if (newWidth < 100) {
        newWidth := 100
    }
    if (newHeight < 100) {
        newHeight := 100
    }
    if (newX < workArea.left) {
        newX := workArea.left
        if (g_WindowResizeInfo.resizeEdge = "left" || g_WindowResizeInfo.resizeEdge = "top-left" || g_WindowResizeInfo.resizeEdge = "bottom-left") {
            newWidth := g_WindowResizeInfo.startWinW - (currentMouseX - g_WindowResizeInfo.startMouseX)
            if (newWidth < 100) {
                newWidth := 100
            }
        }
    }
    if (newY < workArea.top) {
        newY := workArea.top
        if (g_WindowResizeInfo.resizeEdge = "top" || g_WindowResizeInfo.resizeEdge = "top-left" || g_WindowResizeInfo.resizeEdge = "top-right") {
            newHeight := g_WindowResizeInfo.startWinH - (currentMouseY - g_WindowResizeInfo.startMouseY)
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
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeInfo.win
}

ProcessWindowMovement2() {
    global g_WindowMoveInfo, g_CurrentMode
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessWindowMovement2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveInfo.startMouseX
    deltaY := currentMouseY - g_WindowMoveInfo.startMouseY
    newX := g_WindowMoveInfo.startWinX + deltaX
    newY := g_WindowMoveInfo.startWinY + deltaY
    workArea := GetScreenWorkArea(g_WindowMoveInfo.win)
    WinGetPos , , &winWidth, &winHeight, g_WindowMoveInfo.win
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
        WinMove newX, newY, winWidth, winHeight, g_WindowMoveInfo.win
    } else {
        if (newX < workArea.left)
            newX := workArea.left
        if (newY < workArea.top)
            newY := workArea.top
        if (newX + winWidth > workArea.right)
            newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom)
            newY := workArea.bottom - winHeight
        WinMove newX, newY, , , g_WindowMoveInfo.win
    }
    g_WindowMoveInfo.startMouseX := currentMouseX
    g_WindowMoveInfo.startMouseY := currentMouseY
    g_WindowMoveInfo.startWinX := newX
    g_WindowMoveInfo.startWinY := newY
}

#HotIf g_CurrentMode = "window_control2"

LButton:: {
    global g_WindowMoveInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMoveInfo.startMouseX := startMouseX
        g_WindowMoveInfo.startMouseY := startMouseY
        g_WindowMoveInfo.startWinX := startWinX
        g_WindowMoveInfo.startWinY := startWinY
        g_WindowMoveInfo.win := windowUnderCursor
        SetTimer ProcessWindowMovement2, 10
    }
}

LButton Up:: {
    SetTimer ProcessWindowMovement2, 0
}

MButton:: {
    global g_WindowResizeInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
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
                g_WindowResizeInfo.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeInfo.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeInfo.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom"
            } else {
                g_WindowResizeInfo.resizeEdge := "center"
            }
        }
        g_WindowResizeInfo.startMouseX := startMouseX
        g_WindowResizeInfo.startMouseY := startMouseY
        g_WindowResizeInfo.startWinX := startWinX
        g_WindowResizeInfo.startWinY := startWinY
        g_WindowResizeInfo.startWinW := startWinW
        g_WindowResizeInfo.startWinH := startWinH
        g_WindowResizeInfo.win := windowUnderCursor
        SetTimer ProcessWindowResizing2, 10
    }
}

MButton Up:: {
    SetTimer ProcessWindowResizing2, 0
}

WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
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
        ShowTimedTooltip("透明度: " newTransparency)
    }
}

WheelUp:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
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
        ShowTimedTooltip("透明度: " newTransparency)
    }
}

#HotIf

#Requires AutoHotkey v2.0

g_WindowsNoWinKillAndTaskKill := [
    "ahk_exe explorer.exe",
]

EnterWindowKillMode() {
    ModeActionsSet("window_kill",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
    )
}

#HotIf g_CurrentMode = "window_kill"

LButton:: {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        for _, winTitle in g_WindowsNoWinKillAndTaskKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                if MyWinActivate(windowUnderCursor) {
                    Send("^w")
                }
                return
            }
        }
        if MyWinActivate(windowUnderCursor) {
            WinClose(windowUnderCursor) ;;Send("!{F4}")有些窗口不顶用
        }
    }
}

MButton:: {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        for _, winTitle in g_WindowsNoWinKillAndTaskKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                return
            }
        }
        winPID := WinGetPID(windowUnderCursor)
        CmdRunSilent("taskkill /f /pid " winPID)
    }
}

#HotIf
