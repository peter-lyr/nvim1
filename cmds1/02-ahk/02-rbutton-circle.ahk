#Requires AutoHotkey v2.0
DetectHiddenWindows True

global g_CircleGui := ""
global g_CircleHwnd := 0
global g_CircleRadius := 50
global g_CircleCenterX := 0
global g_CircleCenterY := 0
global g_TargetWindowHwnd := 0

global g_LeftClickState := 0, g_MiddleClickState := 0, g_WheelState := 0
global g_MaxLeftClickStates := 1, g_MaxMiddleClickStates := 1, g_MaxWheelStates := 1

global g_CurrentMode := "normal"

global g_DirectionArrowMap := Map(
    "R", "→",
    "RD", "↘",
    "D", "↓",
    "LD", "↙",
    "L", "←",
    "LU", "↖",
    "U", "↑",
    "RU", "↗"
)

global g_DirectionNameMap := Map(
    "R", "右",
    "RD", "右下",
    "D", "下",
    "LD", "左下",
    "L", "左",
    "LU", "左上",
    "U", "上",
    "RU", "右上"
)

global g_ActionFunctionMap := Map()

InitializeActionMappings() {
    global g_ActionFunctionMap
    g_ActionFunctionMap["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    g_ActionFunctionMap["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    g_ActionFunctionMap["000LD"] := ["切换到示例模式2", ExampleFunction2]
    g_ActionFunctionMap["000LU"] := ["切换到媒体控制模式", ExampleFunction1]
    g_ActionFunctionMap["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    g_ActionFunctionMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    g_ActionFunctionMap["000RU"] := ["切换最大化窗口", ToggleMaximizeWindow]
    g_ActionFunctionMap["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    g_ActionFunctionMap["001L"] := ["上一首媒体", Send.Bind("{Media_Prev}")]
    g_ActionFunctionMap["001R"] := ["下一首媒体", Send.Bind("{Media_Next}")]
    g_ActionFunctionMap["010D"] := ["上一个标签页", Send.Bind("^+{Tab}")]
    g_ActionFunctionMap["010U"] := ["下一个标签页", Send.Bind("^{Tab}")]
    g_ActionFunctionMap["100L"] := ["减少系统音量", Send.Bind("{Volume_Down}")]
    g_ActionFunctionMap["100R"] := ["增加系统音量", Send.Bind("{Volume_Up}")]
}

MinimizeTargetWindow() {
    global g_TargetWindowHwnd
    WinMinimize(g_TargetWindowHwnd)
}

ToggleMaximizeWindow() {
    global g_TargetWindowHwnd
    if (WinGetMinMax(g_TargetWindowHwnd) == 1) {
        WinRestore(g_TargetWindowHwnd)
    } else {
        WinMaximize(g_TargetWindowHwnd)
    }
}

ExampleFunction1() {
    global g_CurrentMode := "media"
    ToolTip("已切换到媒体控制模式`n左键:播放/暂停 中键:静音 滚轮:音量 右键:恢复")
    SetTimer(() => ToolTip(), 2000)
}

ExampleFunction2() {
    global g_CurrentMode := "example2"
    ToolTip("已切换到示例模式2`n左键:功能A 中键:功能B 滚轮:功能C 右键:恢复")
    SetTimer(() => ToolTip(), 2000)
}

#HotIf g_CurrentMode = "media"
RButton::
{
    global g_CurrentMode := "normal"
    ToolTip("已恢复原始热键模式")
    SetTimer(() => ToolTip(), 2000)
    RButtonDo()
    return
}

LButton::
{
    Send "{Media_Play_Pause}"
    return
}

MButton::
{
    Send "{Volume_Mute}"
    return
}

WheelUp::
{
    Send "{Volume_Up}"
    return
}

WheelDown::
{
    Send "{Volume_Down}"
    return
}
#HotIf

#HotIf g_CurrentMode = "example2"
RButton::
{
    global g_CurrentMode := "normal"
    ToolTip("已恢复原始热键模式")
    SetTimer(() => ToolTip(), 2000)
    RButtonDo()
    return
}

LButton::
{
    MsgBox "执行示例模式2的功能A"
    return
}

MButton::
{
    MsgBox "执行示例模式2的功能B"
    return
}

WheelUp::
{
    MsgBox "执行示例模式2的功能C（滚轮上）"
    return
}

WheelDown::
{
    MsgBox "执行示例模式2的功能C（滚轮下）"
    return
}
#HotIf

CreateCircleInterface(centerX, centerY, width, height, transparency, bgColor) {
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数（当前宽：" width "，高：" height "）")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间（当前值：" transparency "）")
    posX := centerX - width / 2
    posY := centerY - height / 2
    circleGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    circleGui.BackColor := bgColor
    circleGui.Show("x" posX " y" posY " w" width " h" height " NoActivate")
    WinSetTransparent(transparency, circleGui.Hwnd)
    hRgn := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0,
        "Int", 0,
        "Int", width,
        "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", circleGui.Hwnd, "Ptr", hRgn, "Int", 1)
    return circleGui
}

ShowCircleAtMousePosition() {
    global g_CircleGui, g_CircleHwnd, g_CircleRadius, g_CircleCenterX, g_CircleCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    g_CircleCenterX := mouseX
    g_CircleCenterY := mouseY
    diameter := g_CircleRadius * 2
    if (g_CircleGui && IsObject(g_CircleGui)) {
        posX := mouseX - g_CircleRadius
        posY := mouseY - g_CircleRadius
        g_CircleGui.Show("x" posX " y" posY " w" diameter " h" diameter " NoActivate")
        g_CircleHwnd := g_CircleGui.Hwnd
    } else {
        try {
            g_CircleGui := CreateCircleInterface(mouseX, mouseY, diameter, diameter, 180, "FF0000")
            g_CircleHwnd := g_CircleGui.Hwnd
        }
        catch as e {
            ShowTemporaryTooltip("创建圆形界面失败: " . e.Message)
            g_CircleGui := ""
            g_CircleHwnd := 0
        }
    }
}

HideCircleInterface() {
    global g_CircleGui
    if (g_CircleGui && IsObject(g_CircleGui)) {
        g_CircleGui.Hide()
    }
}

IsMouseWithinCircle() {
    global g_CircleHwnd, g_CircleRadius, g_CircleCenterX, g_CircleCenterY
    if (!g_CircleHwnd)
        return false
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    distance := Sqrt((mouseX - g_CircleCenterX)**2 + (mouseY - g_CircleCenterY)**2)
    return distance <= g_CircleRadius
}

CalculateDirectionFromCenter() {
    global g_CircleCenterX, g_CircleCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    dx := mouseX - g_CircleCenterX
    dy := mouseY - g_CircleCenterY
    angle := DllCall("msvcrt.dll\atan2", "Double", dy, "Double", dx, "Double") * 57.29577951308232
    if (angle < 0)
        angle += 360
    if (angle >= 337.5 || angle < 22.5)
        return "R"
    else if (angle >= 22.5 && angle < 67.5)
        return "RD"
    else if (angle >= 67.5 && angle < 112.5)
        return "D"
    else if (angle >= 112.5 && angle < 157.5)
        return "LD"
    else if (angle >= 157.5 && angle < 202.5)
        return "L"
    else if (angle >= 202.5 && angle < 247.5)
        return "LU"
    else if (angle >= 247.5 && angle < 292.5)
        return "U"
    else if (angle >= 292.5 && angle < 337.5)
        return "RU"
}

GetDirectionDisplayName(directionCode) {
    global g_DirectionNameMap
    return g_DirectionNameMap.Has(directionCode) ? g_DirectionNameMap[directionCode] : directionCode
}

GetDirectionArrowSymbol(directionCode) {
    global g_DirectionArrowMap
    return g_DirectionArrowMap.Has(directionCode) ? g_DirectionArrowMap[directionCode] : "•"
}

GetCurrentStateCombination() {
    global g_LeftClickState, g_MiddleClickState, g_WheelState
    direction := CalculateDirectionFromCenter()
    return g_LeftClickState "" g_MiddleClickState "" g_WheelState "" direction
}

GetFunctionForCurrentState() {
    global g_ActionFunctionMap
    stateKey := GetCurrentStateCombination()
    if (g_ActionFunctionMap.Has(stateKey)) {
        return g_ActionFunctionMap[stateKey]
    } else {
        return "未定义操作"
    }
}

CreateDirectionalOperationDisplay() {
    global g_LeftClickState, g_MiddleClickState, g_WheelState, g_ActionFunctionMap
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
            stateKey := g_LeftClickState "" g_MiddleClickState "" g_WheelState "" directionCode
            operationInfo := g_ActionFunctionMap.Has(stateKey) ? g_ActionFunctionMap[stateKey] : ["未定义操作", ""]
            operationName := operationInfo[1]
            arrowSymbol := GetDirectionArrowSymbol(directionCode)
            directionName := GetDirectionDisplayName(directionCode)
            displayText := arrowSymbol " " directionName ":" operationName
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }
    displayText := "状态: 左键=" g_LeftClickState ", 中键=" g_MiddleClickState ", 滚轮=" g_WheelState "`n`n"
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
                    Loop leftSpaces {
                        line .= " "
                    }
                    line .= column
                    Loop rightSpaces {
                        line .= " "
                    }
                }
            }
        }
        displayText .= line "`n"
    }
    return displayText
}

CreateCurrentDirectionIndicator() {
    directionCode := CalculateDirectionFromCenter()
    arrowSymbol := GetDirectionArrowSymbol(directionCode)
    directionName := GetDirectionDisplayName(directionCode)
    stateKey := GetCurrentStateCombination()
    operationInfo := g_ActionFunctionMap.Has(stateKey) ? g_ActionFunctionMap[stateKey] : ["未定义操作", ""]
    operationName := operationInfo[1]
    return "方向: " arrowSymbol " " directionName "`n操作: " operationName
}

UpdateOperationDisplay() {
    global g_LastDisplayContent
    if (IsMouseWithinCircle()) {
        newContent := CreateDirectionalOperationDisplay()
    } else {
        newContent := CreateCurrentDirectionIndicator()
    }
    if (newContent != g_LastDisplayContent) {
        ToolTip(newContent)
        g_LastDisplayContent := newContent
    }
}

ChangeLeftClickState() {
    global g_LeftClickState, g_MaxLeftClickStates
    g_LeftClickState := Mod(g_LeftClickState + 1, g_MaxLeftClickStates + 1)
}

ChangeMiddleClickState() {
    global g_MiddleClickState, g_MaxMiddleClickStates
    g_MiddleClickState := Mod(g_MiddleClickState + 1, g_MaxMiddleClickStates + 1)
}

ChangeWheelState() {
    global g_WheelState, g_MaxWheelStates
    g_WheelState := Mod(g_WheelState + 1, g_MaxWheelStates + 1)
}

ShowTemporaryTooltip(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), 2000, -1)
}

CaptureWindowUnderCursor() {
    global g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &g_TargetWindowHwnd)
}

ExecuteCurrentOperation() {
    global g_ActionFunctionMap
    stateKey := GetCurrentStateCombination()
    if (g_ActionFunctionMap.Has(stateKey)) {
        operationInfo := g_ActionFunctionMap[stateKey]
        functionRef := operationInfo[2]
        try {
            functionRef()
        } catch as e {
            ShowTemporaryTooltip("执行操作时出错: " e.Message " [" operationInfo[1] "]")
        }
    } else {
        ShowTemporaryTooltip("未定义的操作: " stateKey)
    }
}

RButtonDo() {
    global g_LastDisplayContent := ""
    CaptureWindowUnderCursor()
    ShowCircleAtMousePosition()
    SetTimer(UpdateOperationDisplay, 150)
}

#HotIf g_CurrentMode = "normal"
RButton:: {
    RButtonDo()
}

RButton Up:: {
    SetTimer(UpdateOperationDisplay, 0)
    ToolTip()
    global g_LastDisplayContent := ""
    HideCircleInterface()

    if (IsMouseWithinCircle()) {
        Click "Right"
    } else {
        ExecuteCurrentOperation()
    }
}

~LButton:: {
    if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
        ChangeLeftClickState()
        return
    }
}

~MButton:: {
    if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
        ChangeMiddleClickState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
        ChangeWheelState()
        return
    }
}
#HotIf

InitializeActionMappings()

ShowCircleAtMousePosition()
HideCircleInterface()

^Ins::ExitApp
