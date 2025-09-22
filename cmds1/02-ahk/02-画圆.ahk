#Requires AutoHotkey v2.0
DetectHiddenWindows True

global circleWindow := ""
global circleHwnd := 0
global circleRadius := 50

CreateCircleWindowDo(centerX, centerY, width, height, transparency, bgColor) {
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

CreateCircleWindow() {
    global circleWindow, circleHwnd, circleRadius
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Destroy()
        circleWindow := ""
        circleHwnd := 0
    }
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    diameter := circleRadius * 2
    try {
        circleWindow := CreateCircleWindowDo(mouseX, mouseY, diameter, diameter, 180, "FF0000")
        circleHwnd := circleWindow.Hwnd
    }
    catch as e {
        Print("failed to create circle: " . e.Message)
        circleWindow := ""
        circleHwnd := 0
    }
}

DestroyCircleWindow() {
    global circleWindow, circleHwnd
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Destroy()
        circleWindow := ""
        circleHwnd := 0
    }
}

IsMouseInCircle() {
    global circleHwnd, circleRadius
    if (!circleHwnd)
        return false
    WinGetPos(&winX, &winY, &winW, &winH, circleHwnd)
    centerX := winX + circleRadius
    centerY := winY + circleRadius
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    distance := Sqrt((mouseX - centerX)**2 + (mouseY - centerY)**2)
    return distance <= circleRadius
}

Print(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), 2000, -1)
}

RButton:: {
    CreateCircleWindow()
}

RButton Up:: {
    DestroyCircleWindow()
    Click "Right"
}

CreateCircleWindow()
DestroyCircleWindow()

^Ins::ExitApp
