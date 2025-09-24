; 方向计算工具

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
