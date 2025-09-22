#Requires AutoHotkey v2.0
DetectHiddenWindows True

global g_CircleGui := ""
global g_CircleHwnd := 0
global g_CircleRadius := 50
global g_CircleCenterX := 0
global g_CircleCenterY := 0
global g_TargetWindowHwnd := 0

global g_Counter1 := 0, g_Counter2 := 0, g_Counter3 := 0
global g_Max1 := 6, g_Max2 := 4, g_Max3 := 5

global g_DirectionMap := Map(
    "R", "右",
    "RD", "右下",
    "D", "下",
    "LD", "左下",
    "L", "左",
    "LU", "左上",
    "U", "上",
    "RU", "右上"
)

global g_ActionMap := Map()

InitActionMap() {
    global g_ActionMap
    g_ActionMap["0_0_0_R"] := "MoveRight"
    g_ActionMap["0_0_0_RD"] := "MinimizeWindow"
    g_ActionMap["0_0_0_RU"] := "ToggleMaximizeWindow"
    g_ActionMap["0_0_0_D"] := "MoveDown"
    g_ActionMap["0_0_0_L"] := "MoveLeft"
    g_ActionMap["0_0_0_U"] := "MoveUp"
    g_ActionMap["0_0_0_LU"] := "ExampleAction1"
    g_ActionMap["0_0_0_LD"] := "ExampleAction2"
    g_ActionMap["1_0_0_R"] := "IncreaseVolume"
    g_ActionMap["1_0_0_L"] := "DecreaseVolume"
    g_ActionMap["0_1_0_U"] := "NextTab"
    g_ActionMap["0_1_0_D"] := "PreviousTab"
    g_ActionMap["0_0_1_R"] := "NextMedia"
    g_ActionMap["0_0_1_L"] := "PreviousMedia"
}

MoveRight() {
    Send "{Right}"
}

MoveLeft() {
    Send "{Left}"
}

MoveUp() {
    Send "{Up}"
}

MoveDown() {
    Send "{Down}"
}

MinimizeWindow() {
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

IncreaseVolume() {
    Send "{Volume_Up}"
}

DecreaseVolume() {
    Send "{Volume_Down}"
}

NextTab() {
    Send "^Tab"
}

PreviousTab() {
    Send "^+Tab"
}

NextMedia() {
    Send "{Media_Next}"
}

PreviousMedia() {
    Send "{Media_Prev}"
}

ExampleAction1() {
    MsgBox "执行示例操作1"
}

ExampleAction2() {
    MsgBox "执行示例操作2"
}

CreateCircleGui(centerX, centerY, width, height, transparency, bgColor) {
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数（当前宽：" width "，高：" height "）")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间（当前值：" transparency "）")
    posX := centerX - width / 2
    posY := centerY - height / 2
    myGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    myGui.BackColor := bgColor
    myGui.Show("x" posX " y" posY " w" width " h" height " NoActivate")
    WinSetTransparent(transparency, myGui.Hwnd)
    hRgn := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0,
        "Int", 0,
        "Int", width,
        "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", myGui.Hwnd, "Ptr", hRgn, "Int", 1)
    return myGui
}

ShowCircleAtMouse() {
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
            g_CircleGui := CreateCircleGui(mouseX, mouseY, diameter, diameter, 180, "FF0000")
            g_CircleHwnd := g_CircleGui.Hwnd
        }
        catch as e {
            ShowTempToolTip("创建圆形失败: " . e.Message)
            g_CircleGui := ""
            g_CircleHwnd := 0
        }
    }
}

HideCircle() {
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

GetDirectionFromCircle() {
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

GetDirectionChineseName(direction) {
    global g_DirectionMap
    return g_DirectionMap.Has(direction) ? g_DirectionMap[direction] : direction
}

GetCurrentStateKey() {
    global g_Counter1, g_Counter2, g_Counter3
    direction := GetDirectionFromCircle()
    return g_Counter1 "_" g_Counter2 "_" g_Counter3 "_" direction
}

GetCurrentActionFunctionName() {
    global g_ActionMap
    stateKey := GetCurrentStateKey()

    if (g_ActionMap.Has(stateKey)) {
        return g_ActionMap[stateKey]
    } else {
        return "未定义操作"
    }
}

GetAllDirectionFunctionNames() {
    global g_Counter1, g_Counter2, g_Counter3, g_ActionMap, g_DirectionMap
    directions := ["R", "RD", "D", "LD", "L", "LU", "U", "RU"]
    result := ""

    for direction in directions {
        stateKey := g_Counter1 "_" g_Counter2 "_" g_Counter3 "_" direction
        chineseDirection := GetDirectionChineseName(direction)

        if (g_ActionMap.Has(stateKey)) {
            funcName := g_ActionMap[stateKey]
            result .= chineseDirection " (" direction "): " funcName "`n"
        } else {
            result .= chineseDirection " (" direction "): 未定义操作`n"
        }
    }

    return result
}

UpdateCounterToolTip() {
    global g_CircleHwnd, g_Counter1, g_Counter2, g_Counter3
    if (!g_CircleHwnd)
        return

    if (IsMouseInsideCircle()) {
        tipText := "计数器: " g_Counter1 ", " g_Counter2 ", " g_Counter3 "`n`n"
        tipText .= GetAllDirectionFunctionNames()
        ToolTip(tipText)
    } else {
        actionFuncName := GetCurrentActionFunctionName()
        direction := GetDirectionFromCircle()
        chineseDirection := GetDirectionChineseName(direction)
        ToolTip("当松开右键时执行的操作: " actionFuncName "`n方向: " chineseDirection)
    }
}

IncrementCounter(counterNum) {
    global g_Counter1, g_Counter2, g_Counter3, g_Max1, g_Max2, g_Max3

    if (counterNum = 1) {
        g_Counter1 := Mod(g_Counter1 + 1, g_Max1 + 1)
    } else if (counterNum = 2) {
        g_Counter2 := Mod(g_Counter2 + 1, g_Max2 + 1)
    } else if (counterNum = 3) {
        g_Counter3 := Mod(g_Counter3 + 1, g_Max3 + 1)
    }
}

ShowTempToolTip(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), 2000, -1)
}

CaptureWindowUnderMouse() {
    global g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &g_TargetWindowHwnd)
}

ExecuteCurrentAction() {
    global g_ActionMap
    stateKey := GetCurrentStateKey()

    if (g_ActionMap.Has(stateKey)) {
        actionFuncName := g_ActionMap[stateKey]
        try {
            %actionFuncName%()
        } catch as e {
            ShowTempToolTip("执行操作时出错: " e.Message)
        }
    } else {
        ShowTempToolTip("未定义的操作: " stateKey)
    }
}

RButton:: {
    CaptureWindowUnderMouse()
    ShowCircleAtMouse()
    SetTimer(UpdateCounterToolTip, 100)
}

RButton Up:: {
    SetTimer(UpdateCounterToolTip, 0)
    ToolTip()
    HideCircle()
    if (IsMouseInsideCircle()) {
        Click "Right"
    } else {
        ExecuteCurrentAction()
    }
}

~LButton:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        IncrementCounter(1)
        UpdateCounterToolTip()
        return
    }
}

~MButton:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        IncrementCounter(2)
        UpdateCounterToolTip()
        return
    }
}

~WheelUp::
~WheelDown:: {
    if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
        IncrementCounter(3)
        UpdateCounterToolTip()
        return
    }
}

InitActionMap()
ShowCircleAtMouse()
HideCircle()

^Ins::ExitApp
