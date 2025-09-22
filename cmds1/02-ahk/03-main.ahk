#Requires AutoHotkey v2.0
; 当右键按下时，以按下位置为圆心画一个直径100像素的圆，松开时关闭圆

; 加载包含圆形窗口函数的脚本
#Include 02-画圆.ahk

; RButton:: {
;     GetrButtonWindowHwnd()
;     CreateOrShowCircleWindow()
;     SetTimer(UpdateToolTip, 100)
; }
;
; RButton Up:: {
;     SetTimer(UpdateToolTip, 0)
;     ToolTip()
;     HideCircleWindow()
;     if (IsMouseInCircle()) {
;         Click "Right"
;     } else {
;         HandleProcess()
;     }
; }
;
; CreateOrShowCircleWindow()
; HideCircleWindow()
;
; ^Ins::ExitApp
