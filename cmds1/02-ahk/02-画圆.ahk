; 画一个圆
; 把标题栏去掉，半透明度，不在任务栏显示图标
; 把它弄成一个函数，参数：圆心的x坐标，y坐标，宽度，高度，透明度，背景色
; 加载另一个ahk
; 窗口置顶
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
    ; 1. 参数验证（避免无效输入）
    if (width <= 0 || height <= 0)
        throw Error("宽度和高度必须为正数（当前宽：" width "，高：" height "）")
    if (transparency < 0 || transparency > 255)
        throw Error("透明度必须在0-255之间（当前值：" transparency "）")

    ; 2. 计算窗口左上角坐标（从圆心定位到窗口左上角）
    posX := centerX - width / 2  ; 左上角X = 圆心X - 宽度的一半
    posY := centerY - height / 2 ; 左上角Y = 圆心Y - 高度的一半

    ; 3. 创建Gui窗口（关键：添加+AlwaysOnTop实现置顶）
    ; 样式说明：
    ; -Caption：去掉标题栏；+ToolWindow：不在任务栏显示；+E0x20：鼠标穿透透明区域；+AlwaysOnTop：窗口置顶
    myGui := Gui("-Caption +ToolWindow +E0x20 +AlwaysOnTop")
    myGui.BackColor := bgColor  ; 设置圆形背景色
    myGui.Show("x" posX " y" posY " w" width " h" height " NoActivate")  ; 显示窗口（NoActivate：不抢占焦点）

    ; 4. 设置窗口透明度
    WinSetTransparent(transparency, myGui.Hwnd)

    ; 5. 用GDI创建圆形区域，将窗口裁剪为圆形
    hRgn := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0,     ; 圆形区域左上角X（相对于窗口内部，0即窗口左边界）
        "Int", 0,     ; 圆形区域左上角Y（相对于窗口内部，0即窗口上边界）
        "Int", width, ; 圆形区域右下角X（窗口宽度，即圆形右边界）
        "Int", height,"Ptr") ; 圆形区域右下角Y（窗口高度，即圆形下边界）
    DllCall("user32.dll\SetWindowRgn", "Ptr", myGui.Hwnd, "Ptr", hRgn, "Int", 1)  ; 应用圆形区域到窗口

    ; 6. 返回窗口对象（方便后续销毁/修改窗口）
    return myGui
}
