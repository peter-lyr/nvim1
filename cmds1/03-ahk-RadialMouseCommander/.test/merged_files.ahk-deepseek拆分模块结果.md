将它分为3个大的模块，一个是鼠标右键功能，一个是按键双击alt键的功能，一个是各种热键功能。
每隔功能只有一个文件里调用函数，定义热键，定义变量，可以定义少量函数，其他地方只能定义函数。
定义函数的文件也要拆分模块化，类似的功能放到一个文件里。
每个大的模块单独一个独立的文件夹，只有一个main.ahk文件，运行时只跑它一个，里面只进行简单的初始化。
全局变量不单独放到一个文件里去。
一个函数如果被调用两次及两次以上，则放到同一个文件里。
只能改变变量或函数名，不可改变函数调用和函数定义的结构和逻辑，以免程序跑不起来。

豆包方案：

# AHK脚本模块化拆分方案
按照需求将原AHK脚本拆分为**鼠标右键功能模块**、**双击Alt键功能模块**、**各种热键功能模块**三大模块，每个模块独立文件夹，包含初始化入口`main.ahk`和功能函数文件夹；另设`CommonFunctions`文件夹存放跨模块共享函数，确保函数调用逻辑不变、重复函数统一管理。


## 一、整体目录结构
```
AHK_Modularized/
├─ CommonFunctions/          ; 跨模块共享函数
│  ├─ Common_Tooltip.ahk     ; 提示相关共享函数
│  ├─ Common_WindowBasic.ahk ; 基础窗口工具函数
│  ├─ Common_WindowControl.ahk ; 窗口控制共享函数
│  └─ Common_ModeManage.ahk  ; 模式管理共享函数
├─ MouseRightModule/         ; 鼠标右键功能模块
│  ├─ main.ahk               ; 模块初始化入口
│  └─ Functions/             ; 模块专属函数
│     ├─ MR_RadialMenu.ahk   ; 径向菜单相关函数
│     ├─ MR_ButtonState.ahk  ; 鼠标按钮状态函数
│     ├─ MR_Tooltip.ahk      ; 径向菜单提示函数
│     └─ MR_Action.ahk       ; 右键动作执行函数
├─ DoubleAltModule/          ; 双击Alt键功能模块
│  ├─ main.ahk               ; 模块初始化入口
│  └─ Functions/             ; 模块专属函数
│     ├─ DA_Menu.ahk         ; 菜单核心逻辑函数
│     ├─ DA_Fileserv.ahk     ; Fileserv相关函数
│     └─ DA_WindowActivate.ahk ; 窗口激活辅助函数
└─ HotkeyModule/             ; 各种热键功能模块
   ├─ main.ahk               ; 模块初始化入口
   └─ Functions/             ; 模块专属函数
      ├─ HK_WindowActivate.ahk ; 窗口切换激活函数
      ├─ HK_WindowMoveResize.ahk ; 窗口移动调整函数
      ├─ HK_WindowKill.ahk   ; 窗口关闭/杀死函数
      └─ HK_Compile.ahk      ; 编译/进程相关函数
```


## 二、各模块详细内容

### 1. 共享函数文件夹（CommonFunctions）
#### 1.1 Common_Tooltip.ahk（提示共享函数）
```autohotkey
#Requires AutoHotkey v2.0
; 定时提示函数（多模块调用）
ShowTimedTooltip(message, timeout := 2000) {
    global g_ShowTimedTooltipEn
    if not g_ShowTimedTooltipEn {
        return
    }
    ToolTip(message)
    SetTimer(() => ToolTip(), -timeout)
}
```

#### 1.2 Common_WindowBasic.ahk（基础窗口工具）
```autohotkey
#Requires AutoHotkey v2.0
; 窗口激活等待函数
WinWaitActivate(win) {
    loop 100 {
        if WinExist(win) {
            WinActivate(win)
            if WinActive(win) {
                return 1
            }
        }
    }
    return 0
}

; 安全窗口激活函数
MyWinActivate(winTitle) {
    WinWaitActive(winTitle, , 0.1)
    if (!WinActive(winTitle)) {
        WinActivate(winTitle)
    }
    if (WinActive(winTitle)) {
        return true
    }
    return false
}

; 鼠标点是否在窗口内（优化版）
IsPointInWindowOptimized(hwnd, x, y) {
    rect := Buffer(16, 0)
    if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rect)
        return false
    left := NumGet(rect, 0, "Int")
    top := NumGet(rect, 4, "Int")
    right := NumGet(rect, 8, "Int")
    bottom := NumGet(rect, 12, "Int")
    return (x >= left && x <= right && y >= top && y <= bottom)
}

; 获取Fileserv路径
GetWkSw(file) {
    Home := EnvGet("USERPROFILE")
    return Home . "\w\wk-sw\" . file
}

; 静默执行CMD命令
CmdRunSilent(cmd) {
    shell := ComObject("WScript.Shell")
    launch := "cmd.exe /c " . cmd
    shell.Run(launch, 0, false)
}
```

#### 1.3 Common_WindowControl.ahk（窗口控制共享函数）
```autohotkey
#Requires AutoHotkey v2.0
; 切换窗口最大化/还原
ToggleTargetWindowMaximize(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if (WinGetMinMax(hwnd) = 1) {
        WinRestore(hwnd)
    } else {
        WinMaximize(hwnd)
    }
}

; 最小化目标窗口
MinimizeTargetWindow(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if WinExist(hwnd) = WinExist(GetDesktopClass()) {
        return ;; 桌面不最小化
    }
    WinMinimize(hwnd)
}

; 切换窗口置顶
ToggleTargetWindowTopmost(hwnd := 0) {
    global g_TargetWindowHwnd
    if not hwnd {
        hwnd := g_TargetWindowHwnd
    }
    if (hwnd) {
        currentStyle := WinGetExStyle(hwnd)
        isTopmost := (currentStyle & 0x8)
        if (isTopmost) {
            WinSetAlwaysOnTop false, hwnd
            ShowTimedTooltip("取消窗口置顶")
        } else {
            WinSetAlwaysOnTop true, hwnd
            ShowTimedTooltip("窗口已置顶")
        }
    } else {
        ShowTimedTooltip("没有找到目标窗口")
    }
}

; 降低窗口透明度
TransparencyDown(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    global g_WindowsNoTransparencyControl
    for _, winTitle in g_WindowsNoTransparencyControl {
        if hwnd = WinExist(winTitle) {
            return
        }
    }
    currentTransparency := WinGetTransparent(hwnd)
    if (currentTransparency = "")
        currentTransparency := 255
    newTransparency := currentTransparency - 15
    if (newTransparency < 30)
        newTransparency := 30
    WinSetTransparent newTransparency, hwnd
    ShowTimedTooltip("透明度: " newTransparency)
}

; 提高窗口透明度
TransparencyUp(hwnd := 0) {
    hwnd := WinExist(hwnd)
    if not hwnd {
        return
    }
    global g_WindowsNoTransparencyControl
    for _, winTitle in g_WindowsNoTransparencyControl {
        if hwnd = WinExist(winTitle) {
            return
        }
    }
    currentTransparency := WinGetTransparent(hwnd)
    if (currentTransparency = "")
        currentTransparency := 255
    newTransparency := currentTransparency + 15
    if (newTransparency > 255)
        newTransparency := 255
    WinSetTransparent newTransparency, hwnd
    ShowTimedTooltip("透明度: " newTransparency)
}

; 激活目标窗口
ActivateTargetWindow() {
    global g_TargetWindowHwnd
    WinActivate(g_TargetWindowHwnd)
}

; 点击目标位置
ClickAtTargetPosition() {
    global g_TargetClickPosX, g_TargetClickPosY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&originalX, &originalY)
    Click(g_TargetClickPosX, g_TargetClickPosY, "Left")
    MouseMove(originalX, originalY, 0)
}

; 获取桌面类名
GetDesktopClass() {
    Loop {
        hwnd := WinExist("ahk_class WorkerW")
        if !hwnd
            break
        if ControlGetHwnd("SHELLDLL_DefView1", hwnd) {
            return "ahk_class WorkerW"
        }
    }
    if WinExist("ahk_class Progman")
        return "ahk_class Progman"
    return 0
}
```

#### 1.4 Common_ModeManage.ahk（模式管理共享函数）
```autohotkey
#Requires AutoHotkey v2.0
; 初始化普通模式动作映射
InitializeNormalModeActions() {
    ModeActionsSetDo("normal",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
        "000U", ["窗口激活模式", EnterWindowActivateMode],
        "000D", ["向下移动光标", Send.Bind("{Down}")],
        "000L", ["向左移动光标", Send.Bind("{Left}")],
        "000R", ["向右移动光标", Send.Bind("{Right}")],
        "010R", ["切换菜单提示", ToggleUpdateRadialMenuTooltipEn],
        "010RU", ["切换2秒提示", ToggleShowTimedTooltipEn],
    )
}

; 设置模式动作映射（无提示）
ModeActionsSetDo(modeName, actions*) {
    global g_ModeActionMappings
    global g_CurrentMode := modeName
    actionsMap := Map()
    actionsMap.Set(actions*)
    g_ModeActionMappings[g_CurrentMode] := actionsMap
}

; 设置模式动作映射（带提示）
ModeActionsSet(modeName, actions*) {
    ModeActionsSetDo(modeName, actions*)
    ShowTimedTooltip("已切换到" g_CurrentMode "模式")
}

; 进入普通模式
EnterNormalMode() {
    global g_CurrentMode := "normal"
    ShowTimedTooltip("已恢复到normal模式")
}

; 切换径向菜单提示开关
ToggleUpdateRadialMenuTooltipEn() {
    global g_UpdateRadialMenuTooltipEn
    g_UpdateRadialMenuTooltipEn := 1 - g_UpdateRadialMenuTooltipEn
}

; 切换定时提示开关
ToggleShowTimedTooltipEn() {
    global g_ShowTimedTooltipEn
    g_ShowTimedTooltipEn := 1 - g_ShowTimedTooltipEn
}

; 检测双击（共享逻辑）
IsDoubleClick(timeout := 500) {
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < timeout) {
        return true
    }
    return false
}

; 检测远程桌面是否激活
RemoteDesktopActiveOrRButtonPressed() {
    global remote_desktop_exes, remote_desktop_titles, remote_desktop_classes
    MouseGetPos(, , &currentHwnd)
    try {
        currentWinId := WinGetId(currentHwnd)
    } catch {
        return 0
    }
    for index, exe in remote_desktop_exes {
        if (WinExist(exe) and WinGetId(exe) == currentWinId and WinGetMinMax(exe) == 1) {
            return 1
        }
    }
    for index, c in remote_desktop_classes {
        if (WinExist(c) and WinGetId(c) == currentWinId and WinGetMinMax(c) == 1) {
            return 1
        }
    }
    for index, title in remote_desktop_titles {
        if (WinExist(title) and WinGetId(title) == currentWinId and WinGetMinMax(title) == 1) {
            return 1
        }
    }
    return 0
}
```


### 2. 鼠标右键功能模块（MouseRightModule）
#### 2.1 main.ahk（模块入口）
```autohotkey
#Requires AutoHotkey v2.0
; 1. 定义模块专属全局变量
global g_RadialMenuGui := ""
global g_RadialMenuGuiHwnd := 0
global g_RadialMenuRadius := 5
global g_RadialMenuCenterX := 0
global g_RadialMenuCenterY := 0
global g_TargetWindowHwnd := 0
global g_TargetClickPosX := 0
global g_TargetClickPosY := 0
global g_LeftButtonState := 0, g_MiddleButtonState := 0, g_WheelButtonState := 0
global g_MaxLeftButtonStates := 1, g_MaxMiddleButtonStates := 1, g_MaxWheelButtonStates := 1
global g_DirectionSymbols := Map(
    "R", "→", "RD", "↘", "D", "↓", "LD", "↙",
    "L", "←", "LU", "↖", "U", "↑", "RU", "↗"
)
global g_DirectionNames := Map(
    "R", "右", "RD", "右下", "D", "下", "LD", "左下",
    "L", "左", "LU", "左上", "U", "上", "RU", "右上"
)
global g_ModeActionMappings := Map()
global g_PreviousTooltip := ""
global g_UpdateRadialMenuTooltipEn := 1
global g_ShowTimedTooltipEn := 1
global g_CurrentMode := "normal"

; 2. 包含依赖函数文件
#include ..\CommonFunctions\Common_Tooltip.ahk
#include ..\CommonFunctions\Common_WindowControl.ahk
#include ..\CommonFunctions\Common_ModeManage.ahk
#include .\Functions\MR_RadialMenu.ahk
#include .\Functions\MR_ButtonState.ahk
#include .\Functions\MR_Tooltip.ahk
#include .\Functions\MR_Action.ahk

; 3. 模块初始化
InitializeNormalModeActions()
DisplayRadialMenuAtCursor()
HideRadialMenu()

; 4. 注册鼠标右键相关热键
#HotIf not RemoteDesktopActiveOrRButtonPressed()
; 右键按下：初始化右键功能
RButton:: {
    ResetButtonStates()
    RButtonDo()
}
; 左键+右键：设置左键状态为1
~LButton & RButton:: {
    Global g_LeftButtonState := 1
    RButtonDo()
}
; 右键弹起：执行动作/隐藏菜单
RButton Up:: {
    ExitRadialMenuTooltip()
    HideRadialMenu()
    if (IsCursorInsideRadialMenu()) {
        Click "Right"
    } else {
        ExecuteSelectedAction()
    }
    ResetButtonStates()
}
#HotIf

; 5. 普通模式下的鼠标按钮状态循环
#HotIf g_CurrentMode = "normal"
; 左键：循环左键状态（右键按下时）
~LButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    ; 屏幕最左侧双击：切换o.exe
    MouseGetPos(&x)
    if (x >= 0 && x <= 10 && IsDoubleClick()) {
        ToggleToOExe()
    }
}
; 中键：循环中键状态（右键按下时）
~MButton:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
}
; 滚轮：循环滚轮状态（右键按下时）
~WheelUp::
~WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
}
#HotIf
```

#### 2.2 Functions/MR_RadialMenu.ahk（径向菜单函数）
```autohotkey
#Requires AutoHotkey v2.0
; 创建圆形径向菜单GUI
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
    ; 创建椭圆区域（圆形菜单）
    ellipticalRegion := DllCall("gdi32.dll\CreateEllipticRgn",
        "Int", 0, "Int", 0, "Int", width, "Int", height, "Ptr")
    DllCall("user32.dll\SetWindowRgn", "Ptr", radialMenuGui.Hwnd, "Ptr", ellipticalRegion, "Int", 1)
    return radialMenuGui
}

; 在鼠标位置显示径向菜单
DisplayRadialMenuAtCursor() {
    global g_RadialMenuGui, g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    g_RadialMenuCenterX := cursorX
    g_RadialMenuCenterY := cursorY
    menuDiameter := g_RadialMenuRadius * 2
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        menuX := cursorX - g_RadialMenuRadius
        menuY := cursorY - g_RadialMenuRadius
        g_RadialMenuGui.Show("x" menuX " y" menuY " w" menuDiameter " h" menuDiameter " NoActivate")
        g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
    } else {
        try {
            g_RadialMenuGui := CreateRadialMenuGui(cursorX, cursorY, menuDiameter, menuDiameter, 180, "FF0000")
            g_RadialMenuGuiHwnd := g_RadialMenuGui.Hwnd
        } catch as e {
            ShowTimedTooltip("创建圆形菜单失败: " . e.Message)
            g_RadialMenuGui := ""
            g_RadialMenuGuiHwnd := 0
        }
    }
}

; 隐藏径向菜单
HideRadialMenu() {
    global g_RadialMenuGui
    if (g_RadialMenuGui && IsObject(g_RadialMenuGui)) {
        g_RadialMenuGui.Hide()
    }
}

; 判断鼠标是否在径向菜单内
IsCursorInsideRadialMenu() {
    global g_RadialMenuGuiHwnd, g_RadialMenuRadius, g_RadialMenuCenterX, g_RadialMenuCenterY
    if (!g_RadialMenuGuiHwnd)
        return false
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    ; 计算鼠标到菜单中心的距离（勾股定理）
    distanceFromCenter := Sqrt((cursorX - g_RadialMenuCenterX)**2 + (cursorY - g_RadialMenuCenterY)**2)
    return distanceFromCenter <= g_RadialMenuRadius
}

; 计算鼠标相对于菜单中心的方向
CalculateCursorDirection() {
    global g_RadialMenuCenterX, g_RadialMenuCenterY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    deltaX := cursorX - g_RadialMenuCenterX
    deltaY := cursorY - g_RadialMenuCenterY
    ; 计算角度（弧度转角度）
    angleDegrees := DllCall("msvcrt.dll\atan2", "Double", deltaY, "Double", deltaX, "Double") * 57.29577951308232
    if (angleDegrees < 0)
        angleDegrees += 360
    ; 根据角度判断方向（8个方向）
    if (angleDegrees >= 337.5 || angleDegrees < 22.5)
        return "R"
    else if (angleDegrees >= 22.5 && angleDegrees < 67.5)
        return "RD"
    else if (angleDegrees >= 67.5 && angleDegrees < 112.5)
        return "D"
    else if (angleDegrees >= 112.5 && angleDegrees < 157.5)
        return "LD"
    else if (angleDegrees >= 157.5 && angleDegrees < 202.5)
        return "L"
    else if (angleDegrees >= 202.5 && angleDegrees < 247.5)
        return "LU"
    else if (angleDegrees >= 247.5 && angleDegrees < 292.5)
        return "U"
    else if (angleDegrees >= 292.5 && angleDegrees < 337.5)
        return "RU"
}

; 获取方向中文名称
GetDirectionChineseName(directionCode) {
    global g_DirectionNames
    return g_DirectionNames.Has(directionCode) ? g_DirectionNames[directionCode] : directionCode
}

; 获取方向符号
GetDirectionSymbol(directionCode) {
    global g_DirectionSymbols
    return g_DirectionSymbols.Has(directionCode) ? g_DirectionSymbols[directionCode] : "•"
}
```

#### 2.3 Functions/MR_ButtonState.ahk（按钮状态管理）
```autohotkey
#Requires AutoHotkey v2.0
; 循环切换左键状态
CycleLeftButtonState() {
    global g_LeftButtonState, g_MaxLeftButtonStates
    g_LeftButtonState := Mod(g_LeftButtonState + 1, g_MaxLeftButtonStates + 1)
}

; 循环切换中键状态
CycleMiddleButtonState() {
    global g_MiddleButtonState, g_MaxMiddleButtonStates
    g_MiddleButtonState := Mod(g_MiddleButtonState + 1, g_MaxMiddleButtonStates + 1)
}

; 循环切换滚轮状态
CycleWheelButtonState() {
    global g_WheelButtonState, g_MaxWheelButtonStates
    g_WheelButtonState := Mod(g_WheelButtonState + 1, g_MaxWheelButtonStates + 1)
}

; 重置所有按钮状态为0
ResetButtonStates() {
    global g_LeftButtonState := 0
    global g_MiddleButtonState := 0
    global g_WheelButtonState := 0
}

; 获取当前按钮状态+方向的组合键
GetCurrentButtonStateAndDirection() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    direction := CalculateCursorDirection()
    return g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" direction
}

; 获取当前模式的动作映射表
GetCurrentModeActionMap() {
    global g_ModeActionMappings, g_CurrentMode
    if (!g_ModeActionMappings.Has(g_CurrentMode)) {
        return g_ModeActionMappings["normal"]
    }
    return g_ModeActionMappings[g_CurrentMode]
}
```

#### 2.4 Functions/MR_Tooltip.ahk（径向菜单提示）
```autohotkey
#Requires AutoHotkey v2.0
; 生成径向菜单完整提示内容
GenerateRadialMenuDisplay() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    actionMap := GetCurrentModeActionMap()
    ; 菜单方向布局（5行3列）
    directionLayout := [
        ["", "U", ""],
        ["LU", "", "RU"],
        ["L", "", "R"],
        ["LD", "", "RD"],
        ["", "D", ""]
    ]
    displayGrid := []
    ; 填充每行方向的动作描述
    for row in directionLayout {
        newRow := []
        for directionCode in row {
            if (directionCode = "") {
                newRow.Push("")
                continue
            }
            stateKey := g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" directionCode
            actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
            actionDescription := actionInfo[1]
            directionSymbol := GetDirectionSymbol(directionCode)
            directionName := GetDirectionChineseName(directionCode)
            displayText := directionSymbol " " directionName ":" actionDescription
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }
    ; 拼接最终提示文本（模式+状态+布局）
    displayText := "模式: " g_CurrentMode " 状态: 左键=" g_LeftButtonState ", 中键=" g_MiddleButtonState ", 滚轮=" g_WheelButtonState "`n`n"
    for row in displayGrid {
        line := ""
        for column in row {
            if (column = "") {
                line .= "        "
            } else {
                targetWidth := 20
                currentWidth := StrLen(column)
                ; 文本居中对齐
                if (currentWidth >= targetWidth) {
                    line .= column
                } else {
                    spacesNeeded := targetWidth - currentWidth
                    leftSpaces := spacesNeeded // 2
                    rightSpaces := spacesNeeded - leftSpaces
                    loop leftSpaces { line .= " " }
                    line .= column
                    loop rightSpaces { line .= " " }
                }
            }
        }
        displayText .= line "`n"
    }
    return displayText
}

; 生成当前鼠标方向的简化提示
GenerateCurrentDirectionInfo() {
    directionCode := CalculateCursorDirection()
    directionSymbol := GetDirectionSymbol(directionCode)
    directionName := GetDirectionChineseName(directionCode)
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
    actionDescription := actionInfo[1]
    return "模式: " g_CurrentMode " 方向: " directionSymbol " " directionName "`n操作: " actionDescription
}

; 更新径向菜单提示（定时调用）
UpdateRadialMenuTooltip() {
    global g_PreviousTooltip, g_UpdateRadialMenuTooltipEn
    if not g_UpdateRadialMenuTooltipEn {
        return
    }
    ; 鼠标在菜单内显示完整布局，在外显示简化方向
    if (IsCursorInsideRadialMenu()) {
        newContent := GenerateRadialMenuDisplay()
    } else {
        newContent := GenerateCurrentDirectionInfo()
    }
    ; 内容变化时更新提示
    if (newContent != g_PreviousTooltip) {
        ToolTip(newContent)
        g_PreviousTooltip := newContent
    }
}

; 初始化径向菜单提示（启动定时器）
InitRadialMenuTooltip() {
    global g_PreviousTooltip := ""
    SetTimer(UpdateRadialMenuTooltip, 10) ; 10ms刷新一次
}

; 退出径向菜单提示（停止定时器）
ExitRadialMenuTooltip() {
    ToolTip()
    SetTimer(UpdateRadialMenuTooltip, 0)
    global g_PreviousTooltip := ""
}
```

#### 2.5 Functions/MR_Action.ahk（动作执行）
```autohotkey
#Requires AutoHotkey v2.0
; 捕获鼠标下的目标窗口和点击位置
CaptureWindowUnderCursor() {
    global g_TargetClickPosX, g_TargetClickPosY, g_TargetWindowHwnd
    CoordMode("Mouse", "Screen")
    MouseGetPos(&g_TargetClickPosX, &g_TargetClickPosY, &g_TargetWindowHwnd)
}

; 右键按下时的初始化操作（捕获窗口+显示菜单+启动提示）
RButtonDo() {
    CaptureWindowUnderCursor()
    DisplayRadialMenuAtCursor()
    InitRadialMenuTooltip()
}

; 执行当前选中的动作
ExecuteSelectedAction() {
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    if (actionMap.Has(stateKey)) {
        actionInfo := actionMap[stateKey]
        actionFunction := actionInfo[2]
        try {
            actionFunction() ; 调用动作对应的函数
        } catch as e {
            ShowTimedTooltip("执行操作时出错: " e.Message " [" actionInfo[1] "]")
        }
    } else {
        ShowTimedTooltip("未定义的操作: " stateKey)
    }
}

; 切换到o.exe（鼠标左键双击屏幕左侧调用）
ToggleToOExe() {
    if FileExist(A_ScriptDir "\o.exe") != "A" {
        CmdRunSilent(A_ScriptDir . "\o2exe.bat")
    } else {
        CmdRunSilent(A_ScriptDir . "\o.exe")
    }
    ExitApp
}
```


### 3. 双击Alt键功能模块（DoubleAltModule）
#### 3.1 main.ahk（模块入口）
```autohotkey
#Requires AutoHotkey v2.0
; 1. 定义模块专属全局变量
global g_MenuMode := false          ; 是否处于菜单模式
global g_CurrentMenu := "normal"    ; 当前菜单类型
global g_LastAltPress := 0          ; 上一次Alt按下时间
global g_DoubleClickTime := 300     ; 双击判定时间（ms）
global g_MenuTimer := 0             ; 菜单自动退出定时器
global g_Timeout := 8000            ; 菜单超时时间（ms）
global remote_desktop_exes := [     ; 远程桌面进程列表
    "ahk_exe mstsc.exe"
]
global remote_desktop_classes := [  ; 远程桌面窗口类列表
    "ahk_class TscShellContainerClass"
]
global remote_desktop_titles := []  ; 远程桌面窗口标题列表

; 2. 包含依赖函数文件
#include ..\CommonFunctions\Common_Tooltip.ahk
#include ..\CommonFunctions\Common_WindowBasic.ahk
#include ..\CommonFunctions\Common_WindowControl.ahk
#include .\Functions\DA_Menu.ahk
#include .\Functions\DA_Fileserv.ahk
#include .\Functions\DA_WindowActivate.ahk

; 3. 注册双击Alt热键（核心触发）
~LAlt:: {
    global g_MenuMode, g_LastAltPress, g_DoubleClickTime
    currentTime := A_TickCount
    ; 双击Alt且未在菜单模式：退出远程桌面+进入菜单
    if (currentTime - g_LastAltPress < g_DoubleClickTime && !g_MenuMode) {
        JumpOutSideOffMsTsc()
        EnterMenuMode("normal")
    }
    g_LastAltPress := currentTime
}

; 4. 程序退出时自动退出菜单模式
OnExit((*) => ExitMenuMode())
```

#### 3.2 Functions/DA_Menu.ahk（菜单核心逻辑）
```autohotkey
#Requires AutoHotkey v2.0
; 菜单定义（各菜单的热键-动作映射）
MenuDefinitions := Map(
    "normal", Map(
        "q", ["打开企业微信", ActivateWXWorkExe, false],
        ",", ["打开或激活nvim-0.10.4", ActivateOrRunInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), true],
        ".", ["打开或激活nvim-0.11.4", ActivateOrRun.Bind("ahk_exe nvim-qt.exe", "nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), true],
        "/", ["激活mstsc", ActivateExisted.Bind("ahk_exe mstsc.exe"), false],
        "f", ["fileserv", SwitchMenu.Bind("fileserv"), true],
        "a", ["activate", SwitchMenu.Bind("activate"), true],
        "r", ["run", SwitchMenu.Bind("run"), true]
    ),
    "fileserv", Map(
        "f", ["打开或激活fileserv", ActivateFileserv, false],
        "k", ["关闭fileserv", CloseFileserv, false],
        "r", ["重启fileserv", RestartFileserv, false],
        "u", ["fileserv上传剪贴板", FileServUpClip, false],
        "n", ["返回normal菜单", SwitchMenu.Bind("normal"), true]
    ),
    "activate", Map(
        ",", ["打开或激活nvim-0.10.4", ActivateOrRunInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), true],
        ".", ["打开或激活nvim-0.11.4", ActivateOrRun.Bind("ahk_exe nvim-qt.exe", "nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), true],
        "/", ["激活mstsc", ActivateExisted.Bind("ahk_exe mstsc.exe"), false],
        "n", ["返回normal菜单", SwitchMenu.Bind("normal"), true]
    ),
    "run", Map(
        ",", ["打开nvim-0.10.4", RunInWinR.Bind("ahk_exe nvim-qt.exe", "C:\Program Files\Neovim-0.10.4\bin\nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim"), false],
        ".", ["打开nvim-0.11.4", Run.Bind("nvim-qt.exe -- -u ~/Dp1/lazy/nvim1/init-qt.vim"), false],
        "n", ["返回normal菜单", SwitchMenu.Bind("normal"), true]
    )
)

; 进入指定菜单模式
EnterMenuMode(menuType) {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, g_Timeout, MenuDefinitions
    if (g_MenuMode) {
        return
    }
    g_MenuMode := true
    g_CurrentMenu := menuType
    ; 显示菜单提示
    if (MenuDefinitions.Has(menuType)) {
        ShowMenuTooltip(MenuDefinitions[menuType], menuType . "菜单")
    } else {
        ShowMenuTooltip(Map(), "未知菜单")
    }
    ; 注册菜单热键+ESC退出热键
    RegisterMenuHotkeys(menuType)
    Hotkey("Escape", ExitMenuMode, "On")
    ; 启动菜单超时定时器
    g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
}

; 退出菜单模式
ExitMenuMode(*) {
    global g_MenuMode, g_MenuTimer
    if (!g_MenuMode) {
        return
    }
    g_MenuMode := false
    ; 停止超时定时器
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    ; 取消所有菜单热键+ESC热键
    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    ; 关闭提示
    ToolTip()
}

; 注册指定菜单的热键
RegisterMenuHotkeys(menuType) {
    global MenuDefinitions
    if (MenuDefinitions.Has(menuType)) {
        for key, value in MenuDefinitions[menuType] {
            Hotkey(key, HandleMenuHotkey.Bind(key, menuType), "On")
        }
    }
}

; 取消所有菜单的热键
UnregisterAllMenuHotkeys() {
    global MenuDefinitions
    for menuName, hotkeyMap in MenuDefinitions {
        for key in hotkeyMap {
            try Hotkey(key, "Off")
        }
    }
}

; 显示菜单提示（包含热键、动作、超时信息）
ShowMenuTooltip(hotkeyMap, menuName) {
    global g_Timeout
    tooltipText := menuName . "（" . g_Timeout//1000 . "秒后自动退出，按ESC立即退出）`n"
    for key, value in hotkeyMap {
        tooltipText .= "[" key "] " value[1]
        ; 标记"维持菜单"的动作（执行后不退出菜单）
        if (value[3]) {
            tooltipText .= " (维持菜单)"
        }
        tooltipText .= "`n"
    }
    ToolTip(tooltipText)
}

; 处理菜单热键触发（执行动作+判断是否维持菜单）
HandleMenuHotkey(key, menuType, *) {
    global g_CurrentMenu, g_MenuTimer, g_Timeout, MenuDefinitions
    if (g_CurrentMenu != menuType) {
        return
    }
    if (MenuDefinitions.Has(menuType) && MenuDefinitions[menuType].Has(key)) {
        action := MenuDefinitions[menuType][key][2]
        action.Call() ; 执行动作
        ; 非"维持菜单"动作：执行后退出菜单
        if (!MenuDefinitions[menuType][key][3]) {
            ExitMenuMode()
        } else {
            ; "维持菜单"动作：重置超时定时器
            if (g_MenuTimer) {
                SetTimer(g_MenuTimer, 0)
            }
            g_MenuTimer := SetTimer(ExitMenuMode, -g_Timeout)
        }
    }
}

; 切换菜单类型（从当前菜单切换到目标菜单）
SwitchMenu(targetMenu) {
    global g_MenuMode, g_CurrentMenu, g_MenuTimer, MenuDefinitions
    if (!g_MenuMode || g_CurrentMenu = targetMenu || !MenuDefinitions.Has(targetMenu)) {
        return
    }
    ; 停止当前超时定时器
    if (g_MenuTimer) {
        SetTimer(g_MenuTimer, 0)
        g_MenuTimer := 0
    }
    ; 取消当前菜单热键+ESC热键
    UnregisterAllMenuHotkeys()
    Hotkey("Escape", "Off")
    g_MenuMode := false
    ; 进入目标菜单
    EnterMenuMode(targetMenu)
}

; 退出远程桌面（双击Alt时调用）
JumpOutSideOffMsTsc() {
    ; 退出mstsc全屏/激活状态
    loop 10 {
        if WinActive("ahk_exe mstsc.exe") {
            try {
                WinActivate("ahk_class Shell_TrayWnd") ; 激活任务栏
            }
            if (not WinActive("ahk_exe mstsc.exe")) {
                if (MonitorGetCount() <= 1) {
                    WinMinimize("ahk_exe mstsc.exe") ; 单屏时最小化mstsc
                }
                Break
            }
        }
    }
    ; 退出Windows核心窗口（如UWP窗口）
    loop 10 {
        if WinActive("ahk_class Windows.UI.Core.CoreWindow") {
            Send("{Esc}")
        }
        if (not WinActive("ahk_class Windows.UI.Core.CoreWindow")) {
            Break
        }
    }
}

; 激活企业微信
ActivateWXWorkExe() {
    static s_WxWorkFlag := 0
    ; 若在mstsc中，先发送^!Home退出全屏
    if WinActive("ahk_exe mstsc.exe") {
        Send("^!{Home}")
    }
    if (WinExist("ahk_exe WXWork.exe")) {
        WinActivate("ahk_exe WXWork.exe")
        Send("^!+{F1}") ; 企业微信自定义快捷键
        ; 首次激活显示快捷键提示
        if (s_WxWorkFlag = 0) {
            SetTimer(ShowTimedTooltip.Bind("企业微信快捷键: <Ctrl-Alt-Shift-F1>"), -100)
        }
        s_WxWorkFlag := 1
    }
}
```

#### 3.3 Functions/DA_Fileserv.ahk（Fileserv操作）
```autohotkey
#Requires AutoHotkey v2.0
global fileServExe := "ahk_exe Fileserv.exe" ; Fileserv进程名
global fileServActiveWin := 0                 ; Fileserv激活前的窗口ID

; 激活Fileserv（不存在则启动）
ActivateFileserv() {
    if WinExist(fileServExe) {
        WinActivate(fileServExe)
    } else {
        Run(GetWkSw("Fileserv\Fileserv.exe")) ; 从指定路径启动
    }
    WinWaitActivate(fileServExe)
}

; 关闭Fileserv
CloseFileserv() {
    if not WinExist(fileServExe) {
        return
    }
    wid := WinGetId("A") ; 记录当前激活窗口
    ActivateFileserv()   ; 激活Fileserv
    WinKill(fileServExe) ; 关闭Fileserv
    WinWaitActivate(wid) ; 恢复之前的窗口
}

; 重启Fileserv
RestartFileserv() {
    CloseFileserv()
    ActivateFileserv()
}

; Fileserv上传剪贴板
FileServUpClip() {
    global fileServActiveWin
    wid := WinGetId("A") ; 记录当前激活窗口
    ActivateFileserv()
    Try {
        ; 获取Fileserv窗口位置，点击上传按钮
        WinGetPos(&x1, &y1, , , fileServExe)
        MouseGetPos(&x0, &y0) ; 记录当前鼠标位置
        MouseClick("Left", x1 + 76, y1 + 36, , 0, "D") ; 上传按钮坐标
        Sleep(50)
        MouseMove(x0, y0) ; 恢复鼠标位置
        Sleep(50)
        ControlFocus(ControlGetClassNN("上传剪贴板")) ; 聚焦上传控件
        Sleep(50)
        Send("{Space}") ; 触发上传
    }
    fileServActiveWin := wid
    ; 2秒后恢复之前的窗口
    SetTimer(RestoreWin, -2000)
    ActivateMstscExe() ; 激活mstsc
}

; 恢复Fileserv激活前的窗口
RestoreWin() {
    global fileServActiveWin
    If (fileServActiveWin) {
        WinWaitActivate(fileServActiveWin)
        ActivateMstscExe()
    }
}

; 激活mstsc（重试6次）
ActivateMstscExe() {
    if WinExist("ahk_exe mstsc.exe") {
        loop 6 {
            WinActivate("ahk_exe mstsc.exe")
            if WinActive("ahk_exe mstsc.exe") {
                break
            }
        }
    }
}
```

#### 3.4 Functions/DA_WindowActivate.ahk（窗口激活辅助）
```autohotkey
#Requires AutoHotkey v2.0
; 从窗口列表中选择并激活窗口
ActivateExistedSel(windowList) {
    choices := ""
    windowIDs := []
    ; 生成窗口选择列表（ID+标题）
    for i, windowID in windowList {
        title := WinGetTitle("ahk_id " windowID)
        windowIDs.Push(windowID)
        choices .= i ". " title "`n"
    }
    ; 弹出选择框
    choice := InputBox("请选择要激活的窗口：`n`n" choices, "选择窗口", "w400 h300")
    ; 验证选择并激活
    if (choice.Result = "OK" && IsNumber(choice.Value) && choice.Value >= 1 && choice.Value <= windowList.Length) {
        selectedID := windowIDs[choice.Value]
        WinActivate("ahk_id " selectedID)
        if (WinWaitActive("ahk_id " selectedID, , 2)) {
            return true
        }
    }
    return false
}

; 激活已存在的窗口（不存在则返回false）
ActivateExisted(windowTitle) {
    if (not WinExist(windowTitle)) {
        return false
    }
    WinActivate(windowTitle)
    if (WinWaitActive(windowTitle, , 2)) {
        return true
    }
    return false
}

; 激活或启动窗口（多窗口时循环切换，最小化其他窗口）
ActivateOrRun(windowTitle, appPath) {
    static lastActivation := Map() ; 记录每个窗口的上次激活索引
    DetectHiddenWindows False
    windowList := WinGetList(windowTitle) ; 获取窗口列表
    if (windowList.Length > 0) {
        if (windowList.Length > 1) {
            activeWindowID := WinGetID("A")
            filteredList := []
            ; 过滤掉当前激活的窗口
            for windowID in windowList {
                if (windowID != activeWindowID) {
                    filteredList.Push(windowID)
                }
            }
            ; 无过滤窗口：启动新窗口
            if (filteredList.Length = 0) {
                Run(appPath)
                if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
                    WinActivate(windowTitle)
                    return true
                }
            }
            ; 单个过滤窗口：激活并最小化其他
            else if (filteredList.Length = 1) {
                if (ActivateExisted("ahk_id " filteredList[1])) {
                    lastActivation[windowTitle] := 0
                    for windowID in windowList {
                        if (windowID != filteredList[1]) {
                            try { WinMinimize("ahk_id " windowID) }
                        }
                    }
                    return true
                }
            }
            ; 多个过滤窗口：循环激活
            else {
                if (!lastActivation.Has(windowTitle)) {
                    lastActivation[windowTitle] := 0
                }
                nextIndex := lastActivation[windowTitle] + 1
                if (nextIndex >= filteredList.Length) {
                    nextIndex := 0
                }
                if (ActivateExisted("ahk_id " filteredList[nextIndex + 1])) {
                    lastActivation[windowTitle] := nextIndex
                    for windowID in windowList {
                        if (windowID != filteredList[nextIndex + 1]) {
                            try { WinMinimize("ahk_id " windowID) }
                        }
                    }
                    return true
                }
            }
        }
        ; 单个窗口：直接激活
        else {
            if (ActivateExisted("ahk_id " windowList[1])) {
                lastActivation[windowTitle] := 0
                for windowID in windowList {
                    if (windowID != windowList[1]) {
                        try { WinMinimize("ahk_id " windowID) }
                    }
                }
                return true
            }
        }
    }
    ; 窗口不存在：启动
    else {
        Run(appPath)
        if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
            WinActivate(windowTitle)
            return true
        }
    }
    return false
}

; 通过Win+R启动窗口（避免权限问题）
RunInWinR(windowTitle, appPath) {
    ClipboardOld := A_Clipboard
    Sleep(50)
    A_Clipboard := ""
    A_Clipboard := appPath ; 复制路径到剪贴板
    if !ClipWait(2) { ; 等待剪贴板就绪
        A_Clipboard := ClipboardOld
        ClipboardOld := ""
        return false
    }
    Send("#r") ; 打开Win+R
    if !WinWait("Run", , 3) { ; 等待Run窗口
        A_Clipboard := ClipboardOld
        ClipboardOld := ""
        return false
    }
    WinActivate("Run")
    Sleep(200)
    Send("^v") ; 粘贴路径
    Sleep(300)
    Send("{Enter}") ; 执行
    ; 1秒后恢复剪贴板
    SetTimer(RestoreClipboard.Bind(ClipboardOld), -1000)
    ; 等待窗口并激活
    if (WinWait(windowTitle, , 5) && WinExist(windowTitle)) {
        WinActivate(windowTitle)
        return true
    }
    return false
}

; 激活或通过Win+R启动窗口
ActivateOrRunInWinR(windowTitle, appPath) {
    static lastActivation := Map()
    DetectHiddenWindows False
    windowList := WinGetList(windowTitle)
    if (windowList.Length > 0) {
        ; 逻辑同ActivateOrRun，仅启动方式改为RunInWinR
        if (windowList.Length > 1) {
            activeWindowID := WinGetID("A")
            filteredList := []
            for windowID in windowList {
                if (windowID != activeWindowID) {
                    filteredList.Push(windowID)
                }
            }
            if (filteredList.Length = 0) {
                RunInWinR(windowTitle, appPath)
            } else if (filteredList.Length = 1) {
                if (ActivateExisted("ahk_id " filteredList[1])) {
                    lastActivation[windowTitle] := 0
                    for windowID in windowList {
                        if (windowID != filteredList[1]) {
                            try { WinMinimize("ahk_id " windowID) }
                        }
                    }
                    return true
                }
            } else {
                if (!lastActivation.Has(windowTitle)) {
                    lastActivation[windowTitle] := 0
                }
                nextIndex := lastActivation[windowTitle] + 1
                if (nextIndex >= filteredList.Length) {
                    nextIndex := 0
                }
                if (ActivateExisted("ahk_id " filteredList[nextIndex + 1])) {
                    lastActivation[windowTitle] := nextIndex
                    for windowID in windowList {
                        if (windowID != filteredList[nextIndex + 1]) {
                            try { WinMinimize("ahk_id " windowID) }
                        }
                    }
                    return true
                }
            }
        } else {
            if (ActivateExisted("ahk_id " windowList[1])) {
                lastActivation[windowTitle] := 0
                for windowID in windowList {
                    if (windowID != windowList[1]) {
                        try { WinMinimize("ahk_id " windowID) }
                    }
                }
                return true
            }
        }
    } else {
        RunInWinR(windowTitle, appPath)
    }
    return false
}

; 恢复剪贴板（辅助函数）
RestoreClipboard(ClipboardOld) {
    A_Clipboard := ClipboardOld
    ClipboardOld := ""
    Sleep(50)
}
```


### 4. 各种热键功能模块（HotkeyModule）
#### 4.1 main.ahk（模块入口）
```autohotkey
#Requires AutoHotkey v2.0
; 1. 定义模块专属全局变量
; 窗口调整/移动信息
global g_WindowResizeInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0, startWinW: 0, startWinH: 0, resizeEdge: ""}
global g_WindowMoveInfo := {win: 0, startMouseX: 0, startMouseY: 0, startWinX: 0, startWinY: 0}
; 窗口切换激活相关
global g_WindowList := []          ; 鼠标下的窗口列表
global g_CurrentIndex := 0         ; 当前激活窗口索引
global g_LastMousePos := {x: 0, y: 0} ; 上次鼠标位置
global g_LastActiveHwnd := 0       ; 上次激活窗口ID
global g_OriginalTransparency := Map() ; 窗口原始透明度
global g_ActivateTransparency := 180 ; 激活时窗口透明度
global g_OpacityTimer := 0         ; 透明度恢复定时器
; 模式与过滤列表
global g_CurrentMode := "normal"   ; 当前模式
global g_WindowsNoControl := [     ; 不允许控制的窗口类
    "ahk_class tooltips_class32"
]
global g_WindowsNoTransparencyControl := [ ; 不允许调整透明度的窗口
    "ahk_class tooltips_class32",
    GetDesktopClass()
]
global g_WindowsNoWinKillAndTaskKill := [ ; 不允许关闭/杀死的进程
    "ahk_exe explorer.exe"
]

; 2. 包含依赖函数文件
#include ..\CommonFunctions\Common_Tooltip.ahk
#include ..\CommonFunctions\Common_WindowBasic.ahk
#include ..\CommonFunctions\Common_WindowControl.ahk
#include ..\CommonFunctions\Common_ModeManage.ahk
#include .\Functions\HK_WindowActivate.ahk
#include .\Functions\HK_WindowMoveResize.ahk
#include .\Functions\HK_WindowKill.ahk
#include .\Functions\HK_Compile.ahk

; 3. 注册全局热键（窗口控制类）
; ^#k：切换窗口最大化/还原
^#k:: {
    ToggleTargetWindowMaximize("A")
}
; ^#j：最小化当前窗口
^#j:: {
    MinimizeTargetWindow("A")
}
; ^#m：切换当前窗口置顶
^#m:: {
    ToggleTargetWindowTopmost("A")
}
; ^#h：降低当前窗口透明度
^#h:: {
    TransparencyDown("A")
}
; ^#l：提高当前窗口透明度
^#l:: {
    TransparencyUp("A")
}

; 4. 注册编译/重启热键
^!r:: { ; ^!r：重启脚本
    Reload
}
^!c:: { ; ^!c：编译mouse.exe并退出
    CompileMouseAndRun()
}
^!t:: { ; ^!t：切换到o.exe
    ToggleToOExe()
}

; 5. 模块初始化（初始化普通模式动作）
InitializeNormalModeActions()
```

#### 4.2 Functions/HK_WindowActivate.ahk（窗口切换激活）
```autohotkey
#Requires AutoHotkey v2.0
; 进入窗口激活模式
EnterWindowActivateMode() {
    ModeActionsSet("window_activate",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
    )
}

; 切换窗口（根据方向：WheelUp上一个，WheelDown下一个）
SwitchWindow(direction) {
    global g_WindowList, g_CurrentIndex, g_LastMousePos, g_LastActiveHwnd
    global g_OriginalTransparency, g_OpacityTimer
    ResetOpacityTimer() ; 重置透明度恢复定时器
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)

    ; 鼠标移动超过10像素：重新扫描窗口列表
    if (Abs(mouseX - g_LastMousePos.x) > 10 || Abs(mouseY - g_LastMousePos.y) > 10) {
        RestoreAllWindowsOpacity() ; 恢复所有窗口透明度
        g_WindowList := GetWindowsAtMousePos(mouseX, mouseY) ; 扫描鼠标下的窗口
        g_CurrentIndex := 0
        g_LastMousePos := {x: mouseX, y: mouseY}
        g_LastActiveHwnd := 0
        SetWindowsOpacity(g_ActivateTransparency) ; 设置激活透明度
        ; 显示扫描结果
        if (g_WindowList.Length > 0) {
            ShowTimedTooltip("找到 " g_WindowList.Length " 个窗口")
        } else {
            ShowTimedTooltip("未找到符合条件的窗口")
        }
    }

    if (g_WindowList.Length = 0)
        return

    ; 计算下一个要激活的窗口索引
    if (g_CurrentIndex = 0) {
        g_CurrentIndex := 2
    } else {
        g_CurrentIndex += direction
    }
    ; 索引循环（超出范围时重置）
    if (g_CurrentIndex > g_WindowList.Length)
        g_CurrentIndex := 1
    else if (g_CurrentIndex < 1)
        g_CurrentIndex := g_WindowList.Length

    ; 激活窗口并显示提示
    try {
        hwnd := g_WindowList[g_CurrentIndex]
        if (hwnd = g_LastActiveHwnd) {
            ShowTimedTooltip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd) " (已激活)")
            return
        }
        SwitchToWindow(hwnd)
        g_LastActiveHwnd := hwnd
        ShowTimedTooltip("窗口 " g_CurrentIndex " / " g_WindowList.Length " - " WinGetTitle("ahk_id " hwnd))
    }
}

; 设置窗口透明度（批量）
SetWindowsOpacity(opacity := 180) {
    global g_WindowList, g_OriginalTransparency
    for hwnd in g_WindowList {
        if (!g_OriginalTransparency.Has(hwnd)) {
            try {
                ; 记录原始透明度（默认255）
                originalOpacity := WinGetTransparent("ahk_id " hwnd)
                g_OriginalTransparency[hwnd] := originalOpacity = "" ? 255 : originalOpacity
            } catch {
                g_OriginalTransparency[hwnd] := 255
            }
        }
        try {
            WinSetTransparent(opacity, "ahk_id " hwnd)
        }
    }
}

; 恢复所有窗口的原始透明度
RestoreAllWindowsOpacity() {
    global g_OriginalTransparency
    for hwnd, originalOpacity in g_OriginalTransparency {
        try {
            WinSetTransparent(originalOpacity, "ahk_id " hwnd)
        }
    }
    g_OriginalTransparency.Clear()
}

; 重置透明度恢复定时器（2秒后恢复）
ResetOpacityTimer() {
    global g_OpacityTimer
    if (g_OpacityTimer) {
        SetTimer(g_OpacityTimer, 0)
    }
    g_OpacityTimer := SetTimer(RestoreAllWindowsOpacity, -2000)
}

; 扫描鼠标位置下的所有符合条件的窗口（优化性能）
GetWindowsAtMousePos(mouseX, mouseY) {
    static lastMousePos := {x: 0, y: 0}   ; 上次扫描的鼠标位置
    static lastWindows := []              ; 上次扫描的窗口列表
    static lastTimestamp := 0             ; 上次扫描时间
    ResetOpacityTimer()

    ; 鼠标位置无变化且间隔<500ms：返回缓存的窗口列表（优化性能）
    currentTime := A_TickCount
    if (Abs(mouseX - lastMousePos.x) <= 2 && Abs(mouseY - lastMousePos.y) <= 2 && currentTime - lastTimestamp < 500) {
        return lastWindows
    }

    windows := []
    allWindows := WinGetList() ; 获取所有窗口
    windows.Capacity := allWindows.Length

    ; 过滤符合条件的窗口（可见、非系统窗口、包含标题）
    for hwnd in allWindows {
        style := WinGetStyle("ahk_id " hwnd)
        if (!(style & 0x10000000)) ; 排除无WS_VISIBLE风格的窗口
            continue
        if (WinGetMinMax("ahk_id " hwnd) = -1) ; 排除最小化窗口
            continue
        class := WinGetClass("ahk_id " hwnd)
        ; 排除系统窗口（桌面、任务栏等）
        if (class = "Progman" || class = "WorkerW" || class = "Shell_TrayWnd" ||
            class = "Shell_SecondaryTrayWnd" || class = "NotifyIconOverflowWindow" ||
            class = "Windows.UI.Core.CoreWindow") {
            continue
        }
        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x80) ; 排除WS_EX_DISABLED风格的窗口
            continue
        title := WinGetTitle("ahk_id " hwnd)
        if (title = "") ; 排除无标题的窗口
            continue
        ; 验证鼠标是否在窗口内
        if (IsPointInWindowOptimized(hwnd, mouseX, mouseY)) {
            windows.Push(hwnd)
        }
    }

    ; 更新缓存
    lastMousePos := {x: mouseX, y: mouseY}
    lastWindows := windows
    lastTimestamp := currentTime
    return windows
}

; 切换到指定窗口（恢复最小化+安全激活）
SwitchToWindow(hwnd) {
    if (WinActive("ahk_id " hwnd)) {
        return
    }
    ; 若窗口最小化，先恢复
    if (WinGetMinMax("ahk_id " hwnd) = -1) {
        WinRestore("ahk_id " hwnd)
    }
    ActivateWindowSafely(hwnd)
}

; 安全激活窗口（模拟Alt+Tab避免激活失败）
ActivateWindowSafely(hwnd) {
    SimulateAltTab(hwnd)
    if (!WinActive("ahk_id " hwnd)) {
        try {
            DllCall("SetForegroundWindow", "ptr", hwnd) ; 强制激活（DLL调用）
        }
    }
}

; 模拟Alt+Tab激活窗口（解决部分窗口激活问题）
SimulateAltTab(hwnd) {
    originalHwnd := WinGetID("A")
    if (originalHwnd = hwnd) {
        return
    }
    Send("!{Esc}") ; 发送Alt+Esc触发窗口切换
    WinWaitActive("ahk_id " hwnd, , 0.1)
    if (!WinActive("ahk_id " hwnd)) {
        WinActivate("ahk_id " hwnd)
    }
}

; 窗口激活模式热键：滚轮切换窗口、左键退出模式
#HotIf g_CurrentMode = "window_activate"
WheelUp:: { ; 上一个窗口
    SwitchWindow(-1)
}
WheelDown:: { ; 下一个窗口
    SwitchWindow(1)
}
LButton:: { ; 左键退出模式并恢复透明度
    RestoreAllWindowsOpacity()
    EnterNormalMode()
}
^Del:: { ; ^Del：显示当前鼠标下窗口信息
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    title := WinGetTitle("ahk_id " mouseWin)
    class := WinGetClass("ahk_id " mouseWin)
    style := WinGetStyle("ahk_id " mouseWin)
    exStyle := WinGetExStyle("ahk_id " mouseWin)
    info := "窗口信息：`n"
    info .= "标题: " title "`n"
    info .= "类名: " class "`n"
    info .= "样式: " Format("0x{:X}", style) "`n"
    info .= "扩展样式: " Format("0x{:X}", exStyle) "`n"
    info .= "鼠标位置: " mouseX ", " mouseY "`n"
    info .= "窗口ID: " mouseWin
    MsgBox(info)
}
^End:: { ; ^End：重新扫描窗口列表
    global g_WindowList, g_CurrentIndex, g_LastMousePos, g_LastActiveHwnd
    MouseGetPos(&mouseX, &mouseY)
    g_WindowList := GetWindowsAtMousePos(mouseX, mouseY)
    g_CurrentIndex := 0
    g_LastMousePos := {x: mouseX, y: mouseY}
    g_LastActiveHwnd := 0
    if (g_WindowList.Length > 0) {
        ShowTimedTooltip("重新扫描完成，找到 " g_WindowList.Length " 个窗口")
    } else {
        ShowTimedTooltip("重新扫描完成，未找到窗口")
    }
}
^PgDn:: { ; ^PgDn：显示当前窗口列表
    global g_WindowList, g_CurrentIndex
    if (g_WindowList.Length = 0) {
        MsgBox("没有找到窗口")
        return
    }
    listText := "当前窗口列表：`n`n"
    for index, hwnd in g_WindowList {
        title := WinGetTitle("ahk_id " hwnd)
        class := WinGetClass("ahk_id " hwnd)
        status := (index = g_CurrentIndex) ? " ← 当前" : ""
        listText .= index ". " title " (" class ")" status "`n"
    }
    MsgBox(listText)
}
#HotIf
```

#### 4.3 Functions/HK_WindowMoveResize.ahk（窗口移动与调整）
```autohotkey
#Requires AutoHotkey v2.0
; 进入窗口控制模式（基础版）
EnterWindowControlMode() {
    ModeActionsSet("window_control",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
        "100LU", ["窗口Kill模式", EnterWindowKillMode],
    )
}

; 进入窗口控制模式2（优化版，支持屏幕工作区限制）
EnterWindowControlMode2() {
    ModeActionsSet("window_control2",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式", EnterWindowControlMode],
        "100LU", ["窗口Kill模式", EnterWindowKillMode],
    )
}

; 处理窗口调整大小（基础版）
ProcessWindowResizing() {
    global g_WindowResizeInfo
    if !GetKeyState("MButton", "P") { ; 中键释放时停止
        SetTimer ProcessWindowResizing, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeInfo.startMouseX
    deltaY := currentMouseY - g_WindowResizeInfo.startMouseY
    ; 初始化新位置和大小
    newX := g_WindowResizeInfo.startWinX
    newY := g_WindowResizeInfo.startWinY
    newWidth := g_WindowResizeInfo.startWinW
    newHeight := g_WindowResizeInfo.startWinH

    ; 根据调整边缘计算新大小/位置
    switch g_WindowResizeInfo.resizeEdge {
        case "top-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom-right", "center":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
    }

    ; 限制最小大小（100x100）
    if (newWidth < 100)
        newWidth := 100
    if (newHeight < 100)
        newHeight := 100
    ; 限制窗口不超出屏幕边缘（预留10像素）
    if (newX + newWidth < 10)
        newX := 10 - newWidth
    if (newY + newHeight < 10)
        newY := 10 - newHeight

    ; 应用新大小/位置
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeInfo.win
}

; 处理窗口移动（基础版）
ProcessWindowMovement() {
    global g_WindowMoveInfo
    if !GetKeyState("LButton", "P") { ; 左键释放时停止
        SetTimer ProcessWindowMovement, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveInfo.startMouseX
    deltaY := currentMouseY - g_WindowMoveInfo.startMouseY
    ; 计算新位置
    newX := g_WindowMoveInfo.startWinX + deltaX
    newY := g_WindowMoveInfo.startWinY + deltaY
    ; 应用新位置
    WinMove newX, newY, , , g_WindowMoveInfo.win
}

; 获取窗口所在屏幕的工作区（排除任务栏等）
GetScreenWorkArea(winHwnd) {
    ; 获取窗口所在显示器
    monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHwnd, "UInt", 0x2, "Ptr")
    if (monitorHandle = 0) {
        return {left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight}
    }
    ; 获取显示器信息（工作区）
    monitorInfo := Buffer(40, 0)
    NumPut("UInt", 40, monitorInfo, 0) ; 设置MONITORINFO结构体大小
    if (DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)) {
        workLeft := NumGet(monitorInfo, 20, "Int")
        workTop := NumGet(monitorInfo, 24, "Int")
        workRight := NumGet(monitorInfo, 28, "Int")
        workBottom := NumGet(monitorInfo, 32, "Int")
        return {left: workLeft, top: workTop, right: workRight, bottom: workBottom}
    }
    ; 默认返回整个屏幕
    return {left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight}
}

; 处理窗口调整大小（优化版，支持工作区限制）
ProcessWindowResizing2() {
    global g_WindowResizeInfo, g_CurrentMode
    if !GetKeyState("MButton", "P") {
        SetTimer ProcessWindowResizing2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowResizeInfo.startMouseX
    deltaY := currentMouseY - g_WindowResizeInfo.startMouseY
    workArea := GetScreenWorkArea(g_WindowResizeInfo.win) ; 获取工作区
    ; 初始化新位置和大小
    newX := g_WindowResizeInfo.startWinX
    newY := g_WindowResizeInfo.startWinY
    newWidth := g_WindowResizeInfo.startWinW
    newHeight := g_WindowResizeInfo.startWinH

    ; 根据调整边缘计算新大小/位置（同基础版）
    switch g_WindowResizeInfo.resizeEdge {
        case "top-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "top-right":
            newY := g_WindowResizeInfo.startWinY + deltaY
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH - deltaY
        case "left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
        case "right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
        case "bottom-left":
            newX := g_WindowResizeInfo.startWinX + deltaX
            newWidth := g_WindowResizeInfo.startWinW - deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom":
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "bottom-right":
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
        case "center":
            newX := g_WindowResizeInfo.startWinX + deltaX / 2
            newY := g_WindowResizeInfo.startWinY + deltaY / 2
            newWidth := g_WindowResizeInfo.startWinW + deltaX
            newHeight := g_WindowResizeInfo.startWinH + deltaY
    }

    ; 限制最小大小（100x100）
    if (newWidth < 100) newWidth := 100
    if (newHeight < 100) newHeight := 100

    ; 限制窗口不超出工作区
    if (newX < workArea.left) {
        newX := workArea.left
        ; 左侧调整时重新计算宽度
        if (g_WindowResizeInfo.resizeEdge = "left" || g_WindowResizeInfo.resizeEdge = "top-left" || g_WindowResizeInfo.resizeEdge = "bottom-left") {
            newWidth := g_WindowResizeInfo.startWinW - (currentMouseX - g_WindowResizeInfo.startMouseX)
            if (newWidth < 100) newWidth := 100
        }
    }
    if (newY < workArea.top) {
        newY := workArea.top
        ; 顶部调整时重新计算高度
        if (g_WindowResizeInfo.resizeEdge = "top" || g_WindowResizeInfo.resizeEdge = "top-left" || g_WindowResizeInfo.resizeEdge = "top-right") {
            newHeight := g_WindowResizeInfo.startWinH - (currentMouseY - g_WindowResizeInfo.startMouseY)
            if (newHeight < 100) newHeight := 100
        }
    }
    if (newX + newWidth > workArea.right) {
        newX := workArea.right - newWidth
        ; 超出左侧时强制贴左并调整宽度
        if (newX < workArea.left) {
            newX := workArea.left
            newWidth := workArea.right - workArea.left
        }
    }
    if (newY + newHeight > workArea.bottom) {
        newY := workArea.bottom - newHeight
        ; 超出顶部时强制贴顶并调整高度
        if (newY < workArea.top) {
            newY := workArea.top
            newHeight := workArea.bottom - workArea.top
        }
    }

    ; 应用新大小/位置
    WinMove newX, newY, newWidth, newHeight, g_WindowResizeInfo.win
}

; 处理窗口移动（优化版，支持工作区限制和比例保持）
ProcessWindowMovement2() {
    global g_WindowMoveInfo, g_CurrentMode
    if !GetKeyState("LButton", "P") {
        SetTimer ProcessWindowMovement2, 0
        return
    }
    MouseGetPos &currentMouseX, &currentMouseY
    deltaX := currentMouseX - g_WindowMoveInfo.startMouseX
    deltaY := currentMouseY - g_WindowMoveInfo.startMouseY
    newX := g_WindowMoveInfo.startWinX + deltaX
    newY := g_WindowMoveInfo.startWinY + deltaY
    workArea := GetScreenWorkArea(g_WindowMoveInfo.win) ; 获取工作区
    WinGetPos , , &winWidth, &winHeight, g_WindowMoveInfo.win ; 获取窗口当前大小

    ; 窗口超出工作区时：保持比例缩放并贴边
    if (winWidth > workArea.right - workArea.left || winHeight > workArea.bottom - workArea.top) {
        originalAspectRatio := winWidth / winHeight ; 原始宽高比
        maxWidth := workArea.right - workArea.left
        maxHeight := workArea.bottom - workArea.top
        ; 根据比例计算最大可显示大小
        if (maxWidth / maxHeight > originalAspectRatio) {
            newHeight := maxHeight
            newWidth := Round(newHeight * originalAspectRatio)
        } else {
            newWidth := maxWidth
            newHeight := Round(newWidth / originalAspectRatio)
        }
        ; 限制最小大小
        if (newWidth < 100) newWidth := 100
        if (newHeight < 100) newHeight := 100
        ; 更新窗口大小和位置（贴边）
        winWidth := newWidth
        winHeight := newHeight
        if (newX < workArea.left) newX := workArea.left
        if (newY < workArea.top) newY := workArea.top
        if (newX + winWidth > workArea.right) newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom) newY := workArea.bottom - winHeight
        WinMove newX, newY, winWidth, winHeight, g_WindowMoveInfo.win
    }
    ; 窗口正常大小时：仅限制位置不超出工作区
    else {
        if (newX < workArea.left) newX := workArea.left
        if (newY < workArea.top) newY := workArea.top
        if (newX + winWidth > workArea.right) newX := workArea.right - winWidth
        if (newY + winHeight > workArea.bottom) newY := workArea.bottom - winHeight
        WinMove newX, newY, , , g_WindowMoveInfo.win
    }

    ; 更新移动信息（避免累积误差）
    g_WindowMoveInfo.startMouseX := currentMouseX
    g_WindowMoveInfo.startMouseY := currentMouseY
    g_WindowMoveInfo.startWinX := newX
    g_WindowMoveInfo.startWinY := newY
}

; 窗口控制模式热键（基础版）
#HotIf g_CurrentMode = "window_control"
LButton:: { ; 左键：移动窗口
    global g_WindowMoveInfo
    ; 右键按下时：循环左键状态（继承鼠标右键模块逻辑）
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    ; 排除不允许控制的窗口
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        ; 记录初始鼠标位置和窗口位置
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMoveInfo.startMouseX := startMouseX
        g_WindowMoveInfo.startMouseY := startMouseY
        g_WindowMoveInfo.startWinX := startWinX
        g_WindowMoveInfo.startWinY := startWinY
        g_WindowMoveInfo.win := windowUnderCursor
        ; 启动移动定时器（10ms刷新）
        SetTimer ProcessWindowMovement, 10
    }
}
LButton Up:: { ; 左键释放：停止移动
    SetTimer ProcessWindowMovement, 0
}
MButton:: { ; 中键：调整窗口大小
    global g_WindowResizeInfo
    ; 右键按下时：循环中键状态
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    ; 排除不允许控制的窗口
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        ; 记录初始鼠标位置、窗口位置和大小
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, &startWinW, &startWinH, windowUnderCursor
        ; 根据鼠标在窗口内的相对位置判断调整边缘
        cursorXRelative := startMouseX - startWinX
        cursorYRelative := startMouseY - startWinY
        if (cursorXRelative < startWinW / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeInfo.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeInfo.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom"
            } else {
                g_WindowResizeInfo.resizeEdge := "center"
            }
        }
        ; 保存调整信息
        g_WindowResizeInfo.startMouseX := startMouseX
        g_WindowResizeInfo.startMouseY := startMouseY
        g_WindowResizeInfo.startWinX := startWinX
        g_WindowResizeInfo.startWinY := startWinY
        g_WindowResizeInfo.startWinW := startWinW
        g_WindowResizeInfo.startWinH := startWinH
        g_WindowResizeInfo.win := windowUnderCursor
        ; 启动调整定时器（10ms刷新）
        SetTimer ProcessWindowResizing, 10
    }
}
MButton Up:: { ; 中键释放：停止调整
    SetTimer ProcessWindowResizing, 0
}
; 滚轮：调整窗口透明度
WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    TransparencyDown(windowUnderCursor)
}
WheelUp:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    TransparencyUp(windowUnderCursor)
}
#HotIf

; 窗口控制模式2热键（优化版，支持工作区限制）
#HotIf g_CurrentMode = "window_control2"
LButton:: { ; 左键：移动窗口（优化版）
    global g_WindowMoveInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleLeftButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, , , windowUnderCursor
        g_WindowMoveInfo.startMouseX := startMouseX
        g_WindowMoveInfo.startMouseY := startMouseY
        g_WindowMoveInfo.startWinX := startWinX
        g_WindowMoveInfo.startWinY := startWinY
        g_WindowMoveInfo.win := windowUnderCursor
        SetTimer ProcessWindowMovement2, 10 ; 调用优化版移动函数
    }
}
LButton Up:: { ; 左键释放：停止移动
    SetTimer ProcessWindowMovement2, 0
}
MButton:: { ; 中键：调整窗口大小（优化版）
    global g_WindowResizeInfo
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleMiddleButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        MouseGetPos &startMouseX, &startMouseY
        WinGetPos &startWinX, &startWinY, &startWinW, &startWinH, windowUnderCursor
        ; 同基础版：判断调整边缘
        cursorXRelative := startMouseX - startWinX
        cursorYRelative := startMouseY - startWinY
        if (cursorXRelative < startWinW / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-left"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-left"
            } else {
                g_WindowResizeInfo.resizeEdge := "left"
            }
        } else if (cursorXRelative > startWinW * 2 / 3) {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top-right"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom-right"
            } else {
                g_WindowResizeInfo.resizeEdge := "right"
            }
        } else {
            if (cursorYRelative < startWinH / 3) {
                g_WindowResizeInfo.resizeEdge := "top"
            } else if (cursorYRelative > startWinH * 2 / 3) {
                g_WindowResizeInfo.resizeEdge := "bottom"
            } else {
                g_WindowResizeInfo.resizeEdge := "center"
            }
        }
        ; 保存调整信息
        g_WindowResizeInfo.startMouseX := startMouseX
        g_WindowResizeInfo.startMouseY := startMouseY
        g_WindowResizeInfo.startWinX := startWinX
        g_WindowResizeInfo.startWinY := startWinY
        g_WindowResizeInfo.startWinW := startWinW
        g_WindowResizeInfo.startWinH := startWinH
        g_WindowResizeInfo.win := windowUnderCursor
        SetTimer ProcessWindowResizing2, 10 ; 调用优化版调整函数
    }
}
MButton Up:: { ; 中键释放：停止调整
    SetTimer ProcessWindowResizing2, 0
}
; 滚轮：调整窗口透明度（同基础版）
WheelDown:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        currentTransparency := WinGetTransparent(windowUnderCursor)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency - 15
        if (newTransparency < 30)
            newTransparency := 30
        WinSetTransparent newTransparency, windowUnderCursor
        ShowTimedTooltip("透明度: " newTransparency)
    }
}
WheelUp:: {
    if (IsCursorInsideRadialMenu() && GetKeyState("RButton", "P")) {
        CycleWheelButtonState()
        return
    }
    MouseGetPos , , &windowUnderCursor
    for _, winTitle in g_WindowsNoControl {
        if WinExist(winTitle " ahk_id " windowUnderCursor) {
            return
        }
    }
    if windowUnderCursor {
        currentTransparency := WinGetTransparent(windowUnderCursor)
        if (currentTransparency = "")
            currentTransparency := 255
        newTransparency := currentTransparency + 15
        if (newTransparency > 255)
            newTransparency := 255
        WinSetTransparent newTransparency, windowUnderCursor
        ShowTimedTooltip("透明度: " newTransparency)
    }
}
#HotIf
```

#### 4.4 Functions/HK_WindowKill.ahk（窗口关闭/杀死）
```autohotkey
#Requires AutoHotkey v2.0
; 进入窗口Kill模式
EnterWindowKillMode() {
    ModeActionsSet("window_kill",
        "000RU", ["切换最大化窗口", ToggleTargetWindowMaximize],
        "000RD", ["最小化窗口", MinimizeTargetWindow],
        "000LD", ["Esc", Send.Bind("{Esc}")],
        "000U", ["切换窗口置顶", ToggleTargetWindowTopmost],
        "000D", ["激活窗口", ActivateTargetWindow],
        "000L", ["恢复普通模式", EnterNormalMode],
        "000R", ["单击目标", ClickAtTargetPosition],
        "000LU", ["窗口控制模式2", EnterWindowControlMode2],
    )
}

; 窗口Kill模式热键：双击左键关闭窗口，双击中键杀死进程
#HotIf g_CurrentMode = "window_kill"
LButton:: { ; 双击左键：关闭窗口（排除保护进程）
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        global g_WindowsNoWinKillAndTaskKill
        ; 排除不允许关闭的进程（如explorer）
        for _, winTitle in g_WindowsNoWinKillAndTaskKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                if MyWinActivate(windowUnderCursor) {
                    Send("^w") ; 对保护进程发送Ctrl+W（如浏览器标签页关闭）
                }
                return
            }
        }
        ; 普通进程：激活后关闭
        if MyWinActivate(windowUnderCursor) {
            WinClose(windowUnderCursor) ; 优先WinClose，避免Alt+F4失效场景
        }
    }
}
MButton:: { ; 双击中键：杀死进程（排除保护进程）
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
        MouseGetPos , , &windowUnderCursor
        global g_WindowsNoWinKillAndTaskKill
        ; 排除不允许杀死的进程
        for _, winTitle in g_WindowsNoWinKillAndTaskKill {
            if WinGetProcessName(windowUnderCursor) = WinGetProcessName(winTitle) {
                return
            }
        }
        ; 获取进程PID并强制杀死
        winPID := WinGetPID(windowUnderCursor)
        CmdRunSilent("taskkill /f /pid " winPID)
    }
}
#HotIf
```

#### 4.5 Functions/HK_Compile.ahk（编译/进程启动）
```autohotkey
#Requires AutoHotkey v2.0
; 编译mouse.exe并退出脚本
CompileMouseAndRun() {
    CmdRunSilent(A_ScriptDir . "\mouse2exe.bat")
    ExitApp
}

; 检查mouse.exe是否存在（不存在则编译）
CheckExe() {
    if FileExist(A_ScriptDir "\mouse.exe") != "A" {
        CompileMouseAndRun()
    } else {
        ShowTimedTooltip("mouse started", 800)
    }
}

; 切换/启动o.exe（编译或直接运行）
ToggleToOExe() {
    if FileExist(A_ScriptDir "\o.exe") != "A" {
        CmdRunSilent(A_ScriptDir . "\o2exe.bat")
    } else {
        CmdRunSilent(A_ScriptDir . "\o.exe")
    }
    ExitApp
}

; 检查当前窗口是否为最大化的目标窗口（远程桌面/指定进程）
IsCurWinAndMax(exes := [], titles := [], classes :=  []) {
    MouseGetPos(, , &currentHwnd)
    try {
        currentWinId := WinGetId(currentHwnd)
    } catch {
        return 0
    }
    ; 检查进程列表
    for index, exe in exes {
        if (WinExist(exe) and WinGetId(exe) == currentWinId and WinGetMinMax(exe) == 1) {
            return 1
        }
    }
    ; 检查窗口类列表
    for index, c in classes {
        if (WinExist(c) and WinGetId(c) == currentWinId and WinGetMinMax(c) == 1) {
            return 1
        }
    }
    ; 检查窗口标题列表
    for index, title in titles {
        if (WinExist(title) and WinGetId(title) == currentWinId and WinGetMinMax(title) == 1) {
            return 1
        }
    }
    return 0
}
```


## 三、模块运行说明
1. **独立运行**：每个模块的`main.ahk`是入口文件，运行时仅需双击对应模块的`main.ahk`（需确保AutoHotkey v2.0环境已安装）。
   - 例如：运行鼠标右键功能，仅需打开`MouseRightModule/main.ahk`。

2. **依赖关系**：各模块通过`#include`引用`CommonFunctions`中的共享函数，无需手动复制共享文件，确保目录结构不变即可。

3. **函数调用逻辑**：
   - 模块专属函数仅在本模块内调用，集中放在`Functions`文件夹。
   - 跨模块调用的函数（如`ShowTimedTooltip`、`ToggleTargetWindowMaximize`）统一放在`CommonFunctions`，避免重复定义。

4. **变量管理**：
   - 模块专属全局变量在对应模块的`main.ahk`中定义，函数内通过`global`关键字引用。
   - 共享变量（如窗口过滤列表）按模块归属定义，不单独存放全局变量文件，确保变量作用域清晰。


## 四、验证与调试
1. **功能验证**：运行每个模块后，测试核心功能是否正常（如鼠标右键显示径向菜单、双击Alt打开菜单、热键控制窗口）。
2. **错误排查**：若功能失效，优先检查：
   - `#include`路径是否正确（相对路径基于`main.ahk`所在目录）。
   - 全局变量是否在`main.ahk`中正确定义。
   - 共享函数是否在`CommonFunctions`中存在且未被修改。
3. **兼容性**：脚本基于AutoHotkey v2.0编写，需确保运行环境版本匹配，避免因版本差异导致语法错误。
