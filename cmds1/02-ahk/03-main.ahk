#Requires AutoHotkey v2.0
; 当右键按下时，以按下位置为圆心画一个直径100像素的圆，松开时关闭圆

; 加载包含圆形窗口函数的脚本
#Include 02-画圆.ahk

; RButton:: {
;     global g_LastDisplayContent := ""
;     CaptureWindowUnderCursor()
;     ShowCircleAtMousePosition()
;     SetTimer(UpdateOperationDisplay, 150)
; }
;
; RButton Up:: {
;     SetTimer(UpdateOperationDisplay, 0)
;     ToolTip()
;     global g_LastDisplayContent := ""
;     HideCircleInterface()
;
;     if (IsMouseWithinCircle()) {
;         Click "Right"
;     } else {
;         ExecuteCurrentOperation()
;     }
; }
;
; ~LButton:: {
;     if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
;         ChangeLeftClickState()
;         return
;     }
; }
;
; ~MButton:: {
;     if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
;         ChangeMiddleClickState()
;         return
;     }
; }
;
; ~WheelUp::
; ~WheelDown:: {
;     if (IsMouseWithinCircle() && GetKeyState("RButton", "P")) {
;         ChangeWheelState()
;         return
;     }
; }
;
; InitializeActionMappings()
;
; ShowCircleAtMousePosition()
; HideCircleInterface()
;
; ^Ins::ExitApp
