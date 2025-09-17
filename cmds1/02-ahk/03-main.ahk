#Requires AutoHotkey v2.0
; 当右键按下时，以按下位置为圆心画一个直径100像素的圆，松开时关闭圆

; 加载包含圆形窗口函数的脚本
#Include 02-画圆.ahk

; 全局变量存储圆形窗口对象
global circleWindow := ""

; 右键按下时创建圆形窗口
~RButton:: {
    global circleWindow  ; 明确引用全局变量

    ; 先销毁已存在的圆形窗口（如果有）
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Destroy()
        circleWindow := ""
    }

    CoordMode("Mouse", "Screen")
    ; 获取鼠标当前位置
    MouseGetPos(&mouseX, &mouseY)

    ; 直径100像素
    diameter := 100

    try {
        ; 创建圆形窗口，以鼠标位置为圆心
        circleWindow := CreateCircleWindow(mouseX, mouseY, diameter, diameter, 180, "FF0000")
    }
    catch as e {
        MsgBox("创建圆形失败: " e.Message, "错误", "Icon!")
        circleWindow := ""  ; 重置变量
    }
}

; 右键松开时关闭圆形窗口
~RButton Up:: {
    global circleWindow  ; 明确引用全局变量

    ; 关闭并释放窗口对象
    if (circleWindow && IsObject(circleWindow)) {
        circleWindow.Destroy()
        circleWindow := ""  ; 重置为非对象
    }
}

; 按ESC键退出程序
Esc::ExitApp
