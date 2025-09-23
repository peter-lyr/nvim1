#Requires AutoHotkey v2.0

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
