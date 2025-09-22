#Requires AutoHotkey v2.0
; 当右键按下时，以按下位置为圆心画一个直径100像素的圆，松开时关闭圆

; 加载包含圆形窗口函数的脚本
#Include 02-画圆.ahk

; RButton:: {
;     CaptureWindowUnderMouse()
;     ShowCircleAtMouse()
;     SetTimer(UpdateCounterToolTip, 100)
; }
;
; RButton Up:: {
;     SetTimer(UpdateCounterToolTip, 0)
;     ToolTip()
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
;         UpdateCounterToolTip()
;         return
;     }
; }
;
; ~MButton:: {
;     if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
;         IncrementCounter(2)
;         UpdateCounterToolTip()
;         return
;     }
; }
;
; ~WheelUp::
; ~WheelDown:: {
;     if (IsMouseInsideCircle() && GetKeyState("RButton", "P")) {
;         IncrementCounter(3)
;         UpdateCounterToolTip()
;         return
;     }
; }
;
; InitActionMap()
; ShowCircleAtMouse()
; HideCircle()
;
; ^Ins::ExitApp
