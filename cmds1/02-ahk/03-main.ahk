#Requires AutoHotkey v2.0

; 加载包含圆形窗口函数的脚本
#Include 02-画圆.ahk

; 按ESC键退出程序
Esc::ExitApp

; 主程序
Main()

Main() {
    try {
        ; 调用圆形窗口创建函数
        ; 参数: 圆心X, 圆心Y, 宽度, 高度, 透明度, 背景色
        circleWindow1 := CreateCircleWindow(400, 300, 200, 200, 180, "FF0000")  ; 红色圆形
        circleWindow2 := CreateCircleWindow(700, 300, 150, 150, 200, "00FF00")  ; 绿色圆形
        circleWindow3 := CreateCircleWindow(550, 500, 180, 180, 220, "0000FF")  ; 蓝色圆形

        ; MsgBox("已创建3个圆形窗口`n按ESC键退出", "提示")
    }
    catch as e {
        MsgBox("程序出错: " e.Message, "错误", "Icon!")
        ExitApp
    }
}
