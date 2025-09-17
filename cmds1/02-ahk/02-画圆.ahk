; 画一个圆
; 把标题栏去掉，半透明度，不在任务栏显示图标
; 把它弄成一个函数，参数：圆心的x坐标，y坐标，宽度，高度，透明度，背景色
; 加载另一个ahk
#Requires AutoHotkey v2.0

; 创建圆形窗口的函数
; 参数:
;   centerX - 圆心X坐标
;   centerY - 圆心Y坐标
;   width   - 窗口宽度
;   height  - 窗口高度
;   transparency - 透明度(0-255)
;   bgColor - 背景色(十六进制，如"FF0000"表示红色)
CreateCircleWindow(centerX, centerY, width, height, transparency, bgColor) {
    ; 参数验证
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间")

    ; 根据圆心计算窗口左上角坐标
    posX := centerX - width / 2
    posY := centerY - height / 2

    ; 创建窗口 - 无标题栏，不在任务栏显示
    myGui := Gui("-Caption +ToolWindow +E0x20") ; +E0x20 允许鼠标穿透透明区域
    ; myGui.Title := "圆形窗口"
    myGui.BackColor := bgColor
    ; myGui.SetFont("s10", "Segoe UI")
    ; myGui.Add("Text", "cWhite Center", "圆形窗口")

    ; 显示窗口
    myGui.Show("x" posX " y" posY " w" width " h" height " NoActivate")

    ; 设置透明度
    WinSetTransparent(transparency, myGui.Hwnd)

    ; 创建圆形区域并应用
    hRgn := DllCall("gdi32.dll\CreateEllipticRgn", "Int", 0, "Int", 0, "Int", width, "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", myGui.Hwnd, "Ptr", hRgn, "Int", 1)

    ; 返回窗口对象，方便后续操作
    return myGui
}
