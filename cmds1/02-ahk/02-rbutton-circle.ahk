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

global g_ResizeData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0, initWinW: 0, initWinH: 0, direction: ""}
global g_MoveData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0}

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
    g_ActionFunctionMap["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    g_ActionFunctionMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    g_ActionFunctionMap["000RU"] := ["切换最大化窗口", ToggleMaximizeWindow]
    g_ActionFunctionMap["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    g_ActionFunctionMap["000LU"] := ["窗口控制模式", WindowControlMode]
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

WindowControlMode() {
    global g_CurrentMode := "window_control"
    ToolTip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度 右键:恢复")
    SetTimer(() => ToolTip(), -2000)
}

#HotIf g_CurrentMode = "window_control"

MoveWindow() {
    global g_MoveData
    if !GetKeyState("LButton", "P") {
        SetTimer MoveWindow, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_MoveData.initMouseX
    deltaY := currentMouseY - g_MoveData.initMouseY
    newX := g_MoveData.initWinX + deltaX
    newY := g_MoveData.initWinY + deltaY
    WinMove newX, newY, , , g_MoveData.win
}

ResizeWindow() {
    global g_ResizeData
    if !GetKeyState("MButton", "P") {
        SetTimer ResizeWindow, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_ResizeData.initMouseX
    deltaY := currentMouseY - g_ResizeData.initMouseY
    newX := g_ResizeData.initWinX
    newY := g_ResizeData.initWinY
    newWidth := g_ResizeData.initWinW
    newHeight := g_ResizeData.initWinH
    switch g_ResizeData.direction {
        case "top-left":
            newX := g_ResizeData.initWinX + deltaX
            newY := g_ResizeData.initWinY + deltaY
            newWidth := g_ResizeData.initWinW - deltaX
            newHeight := g_ResizeData.initWinH - deltaY
        case "top":
            newY := g_ResizeData.initWinY + deltaY
            newHeight := g_ResizeData.initWinH - deltaY
        case "top-right":
            newY := g_ResizeData.initWinY + deltaY
            newWidth := g_ResizeData.initWinW + deltaX
            newHeight := g_ResizeData.initWinH - deltaY
        case "left":
            newX := g_ResizeData.initWinX + deltaX
            newWidth := g_ResizeData.initWinW - deltaX
        case "right":
            newWidth := g_ResizeData.initWinW + deltaX
        case "bottom-left":
            newX := g_ResizeData.initWinX + deltaX
            newWidth := g_ResizeData.initWinW - deltaX
            newHeight := g_ResizeData.initWinH + deltaY
        case "bottom":
            newHeight := g_ResizeData.initWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_ResizeData.initWinW + deltaX
            newHeight := g_ResizeData.initWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_ResizeData.win
}

RButton:: {
    global g_CurrentMode := "normal"
    ToolTip("已恢复原始热键模式")
    SetTimer(() => ToolTip(), -2000)
    RButtonDo()
}

LButton:: {
    global g_MoveData
    MouseGetPos , , &MouseWin
    if MouseWin {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, , , MouseWin
        g_MoveData.initMouseX := initMouseX
        g_MoveData.initMouseY := initMouseY
        g_MoveData.initWinX := initWinX
        g_MoveData.initWinY := initWinY
        g_MoveData.win := MouseWin
        SetTimer MoveWindow, 10
    }
}

LButton Up:: {
    SetTimer MoveWindow, 0
}

MButton:: {
    global g_ResizeData
    MouseGetPos , , &MouseWin
    if MouseWin {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, &initWinW, &initWinH, MouseWin
        relX := initMouseX - initWinX
        relY := initMouseY - initWinY
        if (relX < initWinW / 3) {
            if (relY < initWinH / 3) {
                g_ResizeData.direction := "top-left"
            } else if (relY > initWinH * 2 / 3) {
                g_ResizeData.direction := "bottom-left"
            } else {
                g_ResizeData.direction := "left"
            }
        } else if (relX > initWinW * 2 / 3) {
            if (relY < initWinH / 3) {
                g_ResizeData.direction := "top-right"
            } else if (relY > initWinH * 2 / 3) {
                g_ResizeData.direction := "bottom-right"
            } else {
                g_ResizeData.direction := "right"
            }
        } else {
            if (relY < initWinH / 3) {
                g_ResizeData.direction := "top"
            } else if (relY > initWinH * 2 / 3) {
                g_ResizeData.direction := "bottom"
            } else {
                g_ResizeData.direction := "center"
            }
        }
        g_ResizeData.initMouseX := initMouseX
        g_ResizeData.initMouseY := initMouseY
        g_ResizeData.initWinX := initWinX
        g_ResizeData.initWinY := initWinY
        g_ResizeData.initWinW := initWinW
        g_ResizeData.initWinH := initWinH
        g_ResizeData.win := MouseWin
        SetTimer ResizeWindow, 10
    }
}

MButton Up:: {
    SetTimer ResizeWindow, 0
}

WheelDown:: {
    MouseGetPos , , &MouseWin
    if MouseWin {
        currentTrans := WinGetTransparent(MouseWin)
        if (currentTrans = "")
            currentTrans := 255
        newTrans := currentTrans - 15
        if (newTrans < 30)
            newTrans := 30
        WinSetTransparent newTrans, MouseWin
        ToolTip("透明度: " newTrans)
        SetTimer(() => ToolTip(), -1000)
    }
}

WheelUp:: {
    MouseGetPos , , &MouseWin
    if MouseWin {
        currentTrans := WinGetTransparent(MouseWin)
        if (currentTrans = "")
            currentTrans := 255
        newTrans := currentTrans + 15
        if (newTrans > 255)
            newTrans := 255
        WinSetTransparent newTrans, MouseWin
        ToolTip("透明度: " newTrans)
        SetTimer(() => ToolTip(), -1000)
    }
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
    SetTimer(() => ToolTip(), -2000, -1)
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
    SetTimer(UpdateOperationDisplay, 10)
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
