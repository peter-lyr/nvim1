#Requires AutoHotkey v2.0
; 当右键按下时，以按下位置为圆心画一个直径100像素的圆，松开时关闭圆

; 加载包含圆形窗口函数的脚本
#Include 02-画圆.ahk

; RButton:: {
;     global g_LastDisplayText := ""
;     CaptureWindowUnderMouse()
;     ShowCircleAtMouse()
;     SetTimer(UpdateDisplay, 150)
; }
;
; RButton Up:: {
;     SetTimer(UpdateDisplay, 0)
;     ToolTip()
;     global g_LastDisplayText := ""
;     HideCircle()
;     if (IsMouseInsideCircle()) {
;         Click "Right"
;     } else {
;         ExecuteCurrentAction()
;     }
; }
;
; ~LButton:: {
;     if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
;         IncrementCounter(1)
;         return
;     }
; }
;
; ~MButton:: {
;     if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
;         IncrementCounter(2)
;         return
;     }
; }
;
; ~WheelUp::
; ~WheelDown:: {
;     if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
;         IncrementCounter(3)
;         return
;     }
; }
;
; InitActionMap()
;
; ShowCircleAtMouse()
; HideCircle()
;
; ^Ins::ExitApp
