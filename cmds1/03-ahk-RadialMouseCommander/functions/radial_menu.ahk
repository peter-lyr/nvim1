; 圆形菜单相关函数

#Requires AutoHotkey v2.0

; 全局变量
global g_RadialMenuGuiEn := 0
global g_RadialMenuGui := ""
global g_RadialMenuGuiHwnd := 0
global g_RadialMenuRadius := 15
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_TargetWindowHwnd := 0
global g_TargetClickPosX := 0
global g_TargetClickPosY := 0

; 鼠标状态变量
global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1

; 方向映射表
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

; 动作映射表
global g_ModeActionMappings := Map()

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
        "Int", 0,
        "Int", width,
        "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", radialMenuGui.Hwnd, "Ptr", ellipticalRegion, "Int", 1)
    return radialMenuGui
}

DisplayRadialMenuAtCursor() {
    global g_RadialMenuGui, g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY, g_RadialMenuGuiEn
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    g_RadialMenuCenterX := cursorX
    g_RadialMenuCenterY := cursorY
    menuDiameter := g_RadialMenuRadius * 2
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        menuX := cursorX - g_RadialMenuRadius
        menuY := cursorY - g_RadialMenuRadius
        if g_RadialMenuGuiEn {
            g_RadialMenuGui.Show("x" menuX " y" menuY " w" menuDiameter " h" menuDiameter " NoActivate")
        }
        g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
    } else {
        try {
            g_RadialMenuGui := CreateRadialMenuGui(cursorX, cursorY, menuDiameter, menuDiameter, 180, "FF0000")
            g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
        } catch as e {
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

ToggleRadialMenuGuiEn() {
    global g_RadialMenuGuiEn
    g_RadialMenuGuiEn := 1 - g_RadialMenuGuiEn
    ShowTimedTooltipLaterDo("g_RadialMenuGuiEn: " g_RadialMenuGuiEn)
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

CycleWheelButtonStateInc() {
    global g_WheelButtonState, g_MaxWheelButtonStates
    g_WheelButtonState := g_WheelButtonState + 1
    if g_WheelButtonState > g_MaxWheelButtonStates
        g_WheelButtonState := g_MaxWheelButtonStates
}

CycleWheelButtonStateDec() {
    global g_WheelButtonState, g_MaxWheelButtonStates
    g_WheelButtonState := g_WheelButtonState - 1
    if g_WheelButtonState < 0
        g_WheelButtonState := 0
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
