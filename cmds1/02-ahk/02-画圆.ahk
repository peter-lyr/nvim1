#Requires AutoHotkey v2.0

global circleWindow := ""

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
        "Int", height,"Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", myGui.Hwnd, "Ptr", hRgn, "Int", 1)
    return myGui
}

CreateCircleWindow() {
    global circleWindow
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Destroy()
        circleWindow := ""
    }
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    diameter := 100
    try {
        circleWindow := CreateCircleWindowDo(mouseX, mouseY, diameter, diameter, 180, "FF0000")
        WinActivate(circleWindow.Hwnd)
    }
    catch as e {
        MsgBox("创建圆形失败: " e.Message, "错误", "Icon!")
        circleWindow := ""
    }
}

DestroyCricleWindow() {
    global circleWindow
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Destroy()
        circleWindow := ""
    }
}

~RButton:: {
    CreateCircleWindow()
}

~RButton Up:: {
    DestroyCricleWindow()
}

CreateCircleWindow()
DestroyCricleWindow()

Esc::ExitApp
