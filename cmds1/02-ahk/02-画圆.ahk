; 画一个圆

; 创建圆形窗口示例（不使用Gdip）
#Requires AutoHotkey v2.0

; 创建主窗口 - 使用正确的语法
myGui := Gui()
myGui.Title := "圆形示例"
myGui.BackColor := "FF0000" ; 红色背景
myGui.SetFont("s10", "Segoe UI")
myGui.Add("Text", "cWhite Center", "这是一个圆形")

; 设置窗口大小
width := 200
height := 200
myGui.Show("x300 y200 w" width " h" height " NoActivate")

; 获取窗口句柄
hwnd := myGui.Hwnd

; 创建圆形区域并应用到窗口
hRgn := DllCall("gdi32.dll\CreateEllipticRgn", "Int", 0, "Int", 0, "Int", width, "Int", height, "Ptr")
DllCall("user32.dll\SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "Int", 1)

; 保持脚本运行
Esc::ExitApp ; 按ESC键退出
