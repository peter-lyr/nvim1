; 圆形菜单界面功能

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
    global g_RadialMenuGui, g_RadialMenuHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY

    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    g_RadialMenuCenterX := cursorX
    g_RadialMenuCenterY := cursorY
    menuDiameter := g_RadialMenuRadius * 2

    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        menuX := cursorX - g_RadialMenuRadius
        menuY := cursorY - g_RadialMenuRadius
        g_RadialMenuGui.Show("x" menuX " y" menuY " w" menuDiameter " h" menuDiameter " NoActivate")
        g_RadialMenuHwnd := g_RadialMenuGui.Hwnd
    } else {
        try {
            g_RadialMenuGui := CreateRadialMenuGui(cursorX, cursorY, menuDiameter, menuDiameter, 180, "FF0000")
            g_RadialMenuHwnd := g_RadialMenuGui.Hwnd
        }
        catch as e {
            ShowTemporaryMessage("创建圆形菜单失败: " . e.Message)
            g_RadialMenuGui := ""
            g_RadialMenuHwnd := 0
        }
    }
}

HideRadialMenu() {
    global g_RadialMenuGui
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        g_RadialMenuGui.Hide()
    }
}

IsCursorInsideRadialMenu() {
    global g_RadialMenuHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    if (!g_RadialMenuHwnd)
        return false

    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    distanceFromCenter := Sqrt((cursorX - g_RadialMenuCenterX)**2 + (cursorY - g_RadialMenuCenterY)**2)
    return distanceFromCenter <= g_RadialMenuRadius
}

CaptureWindowUnderCursor() {
    global g_TargetClickX, g_TargetClickY, g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(&g_TargetClickX, &g_TargetClickY, &g_TargetWindowHwnd)
}
