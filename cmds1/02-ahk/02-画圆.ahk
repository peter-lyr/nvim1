#Requires AutoHotkey v2.0
DetectHiddenWindows True

global circleWindow := ""
global circleHwnd := 0
global circleRadius := 50
global circleCenterX := 0
global circleCenterY := 0
global rButtonWindowHwnd := 0

CreateOrShowCircleWindowDo(centerX, centerY, width, height, transparency, bgColor) {
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

CreateOrShowCircleWindow() {
    global circleWindow, circleHwnd, circleRadius, circleCenterX, circleCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    circleCenterX := mouseX
    circleCenterY := mouseY
    diameter := circleRadius * 2
    if (circleWindow && IsObject(circleWindow)) {
        posX := mouseX - circleRadius
        posY := mouseY - circleRadius
        circleWindow.Show("x" posX " y" posY " w" diameter " h" diameter " NoActivate")
        circleHwnd := circleWindow.Hwnd
    } else {
        try {
            circleWindow := CreateOrShowCircleWindowDo(mouseX, mouseY, diameter, diameter, 180, "FF0000")
            circleHwnd := circleWindow.Hwnd
        }
        catch as e {
            Print("failed to create circle: " . e.Message)
            circleWindow := ""
            circleHwnd := 0
        }
    }
}

HideCircleWindow() {
    global circleWindow
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Hide()
    }
}

IsMouseInCircle() {
    global circleHwnd, circleRadius, circleCenterX, circleCenterY
    if (!circleHwnd)
        return false
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    distance := Sqrt((mouseX - circleCenterX)**2 + (mouseY - circleCenterY)**2)
    return distance <= circleRadius
}

GetMouseDirection() {
    global circleCenterX, circleCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    dx := mouseX - circleCenterX
    dy := mouseY - circleCenterY
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

UpdateToolTip() {
    global circleHwnd
    if (!circleHwnd)
        return

    if (!IsMouseInCircle()) {
        direction := GetMouseDirection()
        ToolTip("方向: " direction)
    } else {
        ToolTip()
    }
}

Print(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), 2000, -1)
}

GetrButtonWindowHwnd() {
    global rButtonWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &rButtonWindowHwnd)
}

HandleProcess() {
    global rButtonWindowHwnd
    direction := GetMouseDirection()
    if (direction == "右上") {
        if (WinGetMinMax(rButtonWindowHwnd) == 1) {
            WinRestore(rButtonWindowHwnd)
        } else {
            WinMaximize(rButtonWindowHwnd)
        }
    } else if (direction == "右下") {
        WinMinimize(rButtonWindowHwnd)
    }
}

RButton:: {
    GetrButtonWindowHwnd()
    CreateOrShowCircleWindow()
    SetTimer(UpdateToolTip, 100)
}

RButton Up:: {
    SetTimer(UpdateToolTip, 0)
    ToolTip()
    HideCircleWindow()
    if (IsMouseInCircle()) {
        Click "Right"
    } else {
        HandleProcess()
    }
}

CreateOrShowCircleWindow()
HideCircleWindow()

^Ins::ExitApp
