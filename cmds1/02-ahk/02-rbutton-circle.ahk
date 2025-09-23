#Requires AutoHotkey v2.0
DetectHiddenWindows True

; 界面相关变量
global g_CircleGui := ""
global g_CircleHwnd := 0
global g_CircleRadius := 50
global g_CircleCenterX := 0
global g_CircleCenterY := 0
global g_TargetWindowHwnd := 0

; 鼠标状态变量
global g_LeftClickState := 0, g_MiddleClickState := 0, g_WheelState := 0
global g_MaxLeftClickStates := 1, g_MaxMiddleClickStates := 1, g_MaxWheelStates := 1

; 窗口操作变量
global g_WindowResizeData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0, initWinW: 0, initWinH: 0, direction: ""}
global g_WindowMoveData := {win: 0, initMouseX: 0, initMouseY: 0, initWinX: 0, initWinY: 0}

; 模式管理
global g_CurrentMode := "normal"
global g_LastDisplayContent := ""

; 方向映射表
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

; 动作映射表
global g_ActionFunctionMaps := Map()

InitializeActionMappings() {
    global g_ActionFunctionMaps
    normalModeMap := Map()
    normalModeMap["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    normalModeMap["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeMap["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeMap["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeMap["000RU"] := ["切换最大化窗口", ToggleMaximizeWindow]
    normalModeMap["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    normalModeMap["000LU"] := ["窗口控制模式", SwitchToWindowControlMode]
    g_ActionFunctionMaps["normal"] := normalModeMap
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

SwitchToWindowControlMode() {
    global g_CurrentMode := "window_control"
    windowControlMap := Map()
    windowControlMap["000L"] := ["恢复普通模式", SwitchToNormalMode]
    g_ActionFunctionMaps["window_control"] := windowControlMap
    ShowTemporaryTooltip("已切换到窗口控制模式`n左键:移动窗口 中键:调整大小 滚轮:透明度 右键:恢复")
}

SwitchToNormalMode() {
    global g_CurrentMode := "normal"
    ShowTemporaryTooltip("已恢复原始热键模式")
}

#HotIf g_CurrentMode = "window_control"

MoveWindowWithMouse() {
    global g_WindowMoveData
    if !GetKeyState("LButton", "P") {
        SetTimer MoveWindowWithMouse, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveData.initMouseX
    deltaY := currentMouseY - g_WindowMoveData.initMouseY
    newX := g_WindowMoveData.initWinX + deltaX
    newY := g_WindowMoveData.initWinY + deltaY
    WinMove newX, newY, , , g_WindowMoveData.win
}

ResizeWindowWithMouse() {
    global g_WindowResizeData
    if !GetKeyState("MButton", "P") {
        SetTimer ResizeWindowWithMouse, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeData.initMouseX
    deltaY := currentMouseY - g_WindowResizeData.initMouseY
    newX := g_WindowResizeData.initWinX
    newY := g_WindowResizeData.initWinY
    newWidth := g_WindowResizeData.initWinW
    newHeight := g_WindowResizeData.initWinH
    switch g_WindowResizeData.direction {
        case "top-left":
            newX := g_WindowResizeData.initWinX + deltaX
            newY := g_WindowResizeData.initWinY + deltaY
            newWidth := g_WindowResizeData.initWinW - deltaX
            newHeight := g_WindowResizeData.initWinH - deltaY
        case "top":
            newY := g_WindowResizeData.initWinY + deltaY
            newHeight := g_WindowResizeData.initWinH - deltaY
        case "top-right":
            newY := g_WindowResizeData.initWinY + deltaY
            newWidth := g_WindowResizeData.initWinW + deltaX
            newHeight := g_WindowResizeData.initWinH - deltaY
        case "left":
            newX := g_WindowResizeData.initWinX + deltaX
            newWidth := g_WindowResizeData.initWinW - deltaX
        case "right":
            newWidth := g_WindowResizeData.initWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeData.initWinX + deltaX
            newWidth := g_WindowResizeData.initWinW - deltaX
            newHeight := g_WindowResizeData.initWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeData.initWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_WindowResizeData.initWinW + deltaX
            newHeight := g_WindowResizeData.initWinH + deltaY
    }
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeData.win
}

LButton:: {
    global g_WindowMoveData
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, , , mouseWindow
        g_WindowMoveData.initMouseX := initMouseX
        g_WindowMoveData.initMouseY := initMouseY
        g_WindowMoveData.initWinX := initWinX
        g_WindowMoveData.initWinY := initWinY
        g_WindowMoveData.win := mouseWindow
        SetTimer MoveWindowWithMouse, 10
    }
}

LButton Up:: {
    SetTimer MoveWindowWithMouse, 0
}

MButton:: {
    global g_WindowResizeData
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        MouseGetPos &initMouseX, &initMouseY
        WinGetPos &initWinX, &initWinY, &initWinW, &initWinH, mouseWindow
        relativeX := initMouseX - initWinX
        relativeY := initMouseY - initWinY
        if (relativeX < initWinW / 3) {
            if (relativeY < initWinH / 3) {
                g_WindowResizeData.direction := "top-left"
            } else if (relativeY > initWinH * 2 / 3) {
                g_WindowResizeData.direction := "bottom-left"
            } else {
                g_WindowResizeData.direction := "left"
            }
        } else if (relativeX > initWinW * 2 / 3) {
            if (relativeY < initWinH / 3) {
                g_WindowResizeData.direction := "top-right"
            } else if (relativeY > initWinH * 2 / 3) {
                g_WindowResizeData.direction := "bottom-right"
            } else {
                g_WindowResizeData.direction := "right"
            }
        } else {
            if (relativeY < initWinH / 3) {
                g_WindowResizeData.direction := "top"
            } else if (relativeY > initWinH * 2 / 3) {
                g_WindowResizeData.direction := "bottom"
            } else {
                g_WindowResizeData.direction := "center"
            }
        }
        g_WindowResizeData.initMouseX := initMouseX
        g_WindowResizeData.initMouseY := initMouseY
        g_WindowResizeData.initWinX := initWinX
        g_WindowResizeData.initWinY := initWinY
        g_WindowResizeData.initWinW := initWinW
        g_WindowResizeData.initWinH := initWinH
        g_WindowResizeData.win := mouseWindow
        SetTimer ResizeWindowWithMouse, 10
    }
}

MButton Up:: {
    SetTimer ResizeWindowWithMouse, 0
}

WheelDown:: {
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        currentTransparency := WinGetTransparent(mouseWindow)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency - 15
        if (newTransparency < 30)
            newTransparency := 30
        WinSetTransparent newTransparency, mouseWindow
        ShowTemporaryTooltip("透明度: " newTransparency)
    }
}

WheelUp:: {
    MouseGetPos , , &mouseWindow
    if mouseWindow {
        currentTransparency := WinGetTransparent(mouseWindow)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency + 15
        if (newTransparency > 255)
            newTransparency := 255
        WinSetTransparent newTransparency, mouseWindow
        ShowTemporaryTooltip("透明度: " newTransparency)
    }
}

#HotIf

CreateCircleGui(centerX, centerY, width, height, transparency, backgroundColor) {
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数（当前宽：" width "，高：" height "）")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间（当前值：" transparency "）")
    positionX := centerX - width / 2
    positionY := centerY - height / 2
    circleGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    circleGui.BackColor := backgroundColor
    circleGui.Show("x" positionX " y" positionY " w" width " h" height " NoActivate")
    WinSetTransparent(transparency, circleGui.Hwnd)
    regionHandle := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0,
        "Int", 0,
        "Int", width,
        "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", circleGui.Hwnd, "Ptr", regionHandle, "Int", 1)
    return circleGui
}

ShowCircleGuiAtMousePosition() {
    global g_CircleGui, g_CircleHwnd, g_CircleRadius, g_CircleCenterX, g_CircleCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    g_CircleCenterX := mouseX
    g_CircleCenterY := mouseY
    diameter := g_CircleRadius * 2
    if (g_CircleGui && IsObject(g_CircleGui)) {
        positionX := mouseX - g_CircleRadius
        positionY := mouseY - g_CircleRadius
        g_CircleGui.Show("x" positionX " y" positionY " w" diameter " h" diameter " NoActivate")
        g_CircleHwnd := g_CircleGui.Hwnd
    } else {
        try {
            g_CircleGui := CreateCircleGui(mouseX, mouseY, diameter, diameter, 180, "FF0000")
            g_CircleHwnd := g_CircleGui.Hwnd
        }
        catch as e {
            ShowTemporaryTooltip("创建圆形界面失败: " . e.Message)
            g_CircleGui := ""
            g_CircleHwnd := 0
        }
    }
}

HideCircleGui() {
    global g_CircleGui
    if (g_CircleGui && IsObject(g_CircleGui)) {
        g_CircleGui.Hide()
    }
}

IsMouseInsideCircle() {
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
    deltaX := mouseX - g_CircleCenterX
    deltaY := mouseY - g_CircleCenterY
    angle := DllCall("msvcrt.dll\atan2", "Double", deltaY, "Double", deltaX, "Double") * 57.29577951308232
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

GetCurrentActionMap() {
    global g_ActionFunctionMaps, g_CurrentMode
    if (!g_ActionFunctionMaps.Has(g_CurrentMode)) {
        return g_ActionFunctionMaps["normal"]
    }
    return g_ActionFunctionMaps[g_CurrentMode]
}

CreateDirectionalOperationDisplay() {
    global g_LeftClickState, g_MiddleClickState, g_WheelState
    actionMap := GetCurrentActionMap()
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
            operationInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
            operationName := operationInfo[1]
            arrowSymbol := GetDirectionArrowSymbol(directionCode)
            directionName := GetDirectionDisplayName(directionCode)
            displayText := arrowSymbol " " directionName ":" operationName
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }
    displayText := "模式: " g_CurrentMode " 状态: 左键=" g_LeftClickState ", 中键=" g_MiddleClickState ", 滚轮=" g_WheelState "`n`n"
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
    actionMap := GetCurrentActionMap()
    operationInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
    operationName := operationInfo[1]
    return "模式: " g_CurrentMode " 方向: " arrowSymbol " " directionName "`n操作: " operationName
}

UpdateOperationDisplayTooltip() {
    global g_LastDisplayContent
    if (IsMouseInsideCircle()) {
        newContent := CreateDirectionalOperationDisplay()
    } else {
        newContent := CreateCurrentDirectionIndicator()
    }
    if (newContent != g_LastDisplayContent) {
        ToolTip(newContent)
        g_LastDisplayContent := newContent
    }
}

CycleLeftClickState() {
    global g_LeftClickState, g_MaxLeftClickStates
    g_LeftClickState := Mod(g_LeftClickState + 1, g_MaxLeftClickStates + 1)
}

CycleMiddleClickState() {
    global g_MiddleClickState, g_MaxMiddleClickStates
    g_MiddleClickState := Mod(g_MiddleClickState + 1, g_MaxMiddleClickStates + 1)
}

CycleWheelState() {
    global g_WheelState, g_MaxWheelStates
    g_WheelState := Mod(g_WheelState + 1, g_MaxWheelStates + 1)
}

ShowTemporaryTooltip(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -2000)
}

CaptureWindowUnderCursor() {
    global g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &g_TargetWindowHwnd)
}

ExecuteCurrentOperation() {
    stateKey := GetCurrentStateCombination()
    actionMap := GetCurrentActionMap()
    if (actionMap.Has(stateKey)) {
        operationInfo := actionMap[stateKey]
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

OnRButtonPress() {
    global g_LastDisplayContent := ""
    CaptureWindowUnderCursor()
    ShowCircleGuiAtMousePosition()
    SetTimer(UpdateOperationDisplayTooltip, 10)
}

#HotIf g_CurrentMode = "normal"

~LButton:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        CycleLeftClickState()
        return
    }
}

~MButton:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        CycleMiddleClickState()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        CycleWheelState()
        return
    }
}
#HotIf

RButton:: {
    OnRButtonPress()
}

RButton Up:: {
    SetTimer(UpdateOperationDisplayTooltip, 0)
    ToolTip()
    global g_LastDisplayContent := ""
    HideCircleGui()
    if (IsMouseInsideCircle()) {
        Click "Right"
    } else {
        ExecuteCurrentOperation()
    }
}

InitializeActionMappings()
ShowCircleGuiAtMousePosition()
HideCircleGui()

^Ins::ExitApp
