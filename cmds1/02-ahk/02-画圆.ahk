#Requires AutoHotkey v2.0
DetectHiddenWindows True

global g_CircleGui := ""
global g_CircleHwnd := 0
global g_CircleRadius := 50
global g_CircleCenterX := 0
global g_CircleCenterY := 0
global g_TargetWindowHwnd := 0

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
        return "右"
    else if (angle >= 22.5 && angle < 67.5)
        return "右下"
    else if (angle >= 67.5 && angle < 112.5)
        return "下"
    else if (angle >= 112.5 && angle < 157.5)
        return "左下"
    else if (angle >= 157.5 && angle < 202.5)
        return "左"
    else if (angle >= 202.5 && angle < 247.5)
        return "左上"
    else if (angle >= 247.5 && angle < 292.5)
        return "上"
    else if (angle >= 292.5 && angle < 337.5)
        return "右上"
}

UpdateDirectionToolTip() {
    global g_CircleHwnd
    if (!g_CircleHwnd)
        return

    if (!IsMouseInsideCircle()) {
        direction := GetDirectionFromCircle()
        ToolTip("方向: " direction)
    } else {
        ToolTip()
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

HandleWindowByDirection() {
    global g_TargetWindowHwnd
    direction := GetDirectionFromCircle()
    if (direction == "右上") {
        if (WinGetMinMax(g_TargetWindowHwnd) == 1) {
            WinRestore(g_TargetWindowHwnd)
        } else {
            WinMaximize(g_TargetWindowHwnd)
        }
    } else if (direction == "右下") {
        WinMinimize(g_TargetWindowHwnd)
    }
}

RButton:: {
    CaptureWindowUnderMouse()
    ShowCircleAtMouse()
    SetTimer(UpdateDirectionToolTip, 100)
}

RButton Up:: {
    SetTimer(UpdateDirectionToolTip, 0)
    ToolTip()
    HideCircle()
    if (IsMouseInsideCircle()) {
        Click "Right"
    } else {
        HandleWindowByDirection()
    }
}

ShowCircleAtMouse()
HideCircle()

^Ins::ExitApp
