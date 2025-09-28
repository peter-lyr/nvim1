import re
import os
from pathlib import Path


def optimize_ahk_naming(original_ahk_path, output_ahk_path):
    """
    优化 AHK 脚本的变量名和函数名
    :param original_ahk_path: 原 AHK 文件路径
    :param output_ahk_path: 优化后 AHK 文件输出路径
    """
    # --------------------------
    # 1. 定义替换映射表（关键：原名称 → 优化后名称）
    # --------------------------
    # 1.1 全局变量替换（含 g_ 前缀，确保精准匹配）
    var_replacements = {
        "g_PreviousTooltip": "g_PreviousRadialMenuTooltip",
        "g_UpdateRadialMenuTooltipEn": "g_IsRadialMenuTooltipUpdateEnabled",
        "g_ShowTimedTooltipEn": "g_IsTimedTooltipDisplayEnabled",
        "g_WindowResizeInfo": "g_WindowResizeState",
        "g_WindowMoveInfo": "g_WindowMovementState",
        "g_CurrentMode": "g_CurrentOperationMode",
        "g_WindowList": "g_TargetWindowList",
        "g_CurrentIndex": "g_CurrentWindowIndex",
        "g_LastActiveHwnd": "g_LastActiveWindowHwnd",
        "g_OriginalTransparency": "g_OriginalWindowTransparency",
        "g_ActivateTransparency": "g_TargetWindowActivateOpacity",
        "g_OpacityTimer": "g_WindowOpacityRestoreTimer",
        "g_RadialMenuGui": "g_RadialMenuGuiObj",
        "g_RadialMenuRadius": "g_RadialMenuRadiusPx",
        "g_RadialMenuCenterX": "g_RadialMenuCenterPosX",
        "g_RadialMenuCenterY": "g_RadialMenuCenterPosY",
        "g_TargetWindowHwnd": "g_CapturedWindowHwnd",
        "g_TargetClickPosX": "g_CapturedMouseClickPosX",
        "g_TargetClickPosY": "g_CapturedMouseClickPosY",
        "g_LeftButtonState": "g_LeftMouseButtonState",
        "g_MiddleButtonState": "g_MiddleMouseButtonState",
        "g_WheelButtonState": "g_WheelMouseButtonState",
        "g_MaxLeftButtonStates": "g_MaxLeftMouseButtonStates",
        "g_MaxMiddleButtonStates": "g_MaxMiddleMouseButtonStates",
        "g_MaxWheelButtonStates": "g_MaxWheelMouseButtonStates",
        "g_ModeActionMappings": "g_OperationModeActionMap",
        "remote_desktop_exes": "g_RemoteDesktopExeList",
        "remote_desktop_classes": "g_RemoteDesktopClassList",
        "remote_desktop_titles": "g_RemoteDesktopTitleList",
        "g_WindowsNoTransparencyControl": "g_WindowsExemptFromTransparency",
        "g_MenuMode": "g_IsMenuModeActive",
        "g_CurrentMenu": "g_CurrentMenuType",
        "g_LastAltPress": "g_LastAltKeyPressTime",
        "g_DoubleClickTime": "g_MenuDoubleClickTimeoutMs",
        "g_MenuTimer": "g_MenuAutoExitTimer",
        "g_Timeout": "g_MenuAutoExitTimeoutMs",
        "MenuDefinitions": "g_MenuDefinitionsMap",
        "g_WindowsNoControl": "g_WindowsExemptFromWindowControl",
        "g_WindowsNoWinKillAndTaskKill": "g_WindowsExemptFromCloseAndKill",
    }

    # 1.2 函数名替换（不含括号，匹配函数定义/调用）
    func_replacements = {
        # FileServ 相关
        "ActivateFileserv": "ActivateFileServWindow",
        "CloseFileserv": "CloseFileServWindow",
        "RestartFileserv": "RestartFileServProcess",
        "RestoreWin": "RestorePreviouslyActiveWindow",
        "FileServUpClip": "UploadClipboardToFileServ",
        # 径向菜单相关
        "CreateRadialMenuGui": "CreateRadialMenuGuiObj",
        "DisplayRadialMenuAtCursor": "ShowRadialMenuAtCursorPos",
        "IsCursorInsideRadialMenu": "IsCursorWithinRadialMenu",
        "CalculateCursorDirection": "CalculateCursorDirRelativeToRadialMenu",
        "GetDirectionChineseName": "GetDirectionChineseDisplayName",
        "GetCurrentButtonStateAndDirection": "GetMouseBtnStateAndDirection",
        "GetCurrentModeActionMap": "GetCurrentOperationModeActionMap",
        "GenerateRadialMenuDisplay": "GenerateRadialMenuTooltipText",
        "GenerateCurrentDirectionInfo": "GenerateCursorDirectionInfo",
        "CycleLeftButtonState": "CycleLeftMouseButtonState",
        "CycleMiddleButtonState": "CycleMiddleMouseButtonState",
        "CycleWheelButtonState": "CycleWheelMouseButtonState",
        "CaptureWindowUnderCursor": "CaptureWindowUnderCursorPos",
        "ResetButtonStates": "ResetAllMouseButtonStates",
        "ExecuteSelectedAction": "ExecuteSelectedRadialMenuAction",
        # 提示相关
        "ToggleUpdateRadialMenuTooltipEn": "ToggleRadialMenuTooltipUpdate",
        "ToggleShowTimedTooltipEn": "ToggleTimedTooltipDisplay",
        "ShowTimedTooltip": "ShowTemporaryTooltip",
        "UpdateRadialMenuTooltip": "UpdateRadialMenuTooltipContent",
        "InitRadialMenuTooltip": "InitializeRadialMenuTooltip",
        "ExitRadialMenuTooltip": "CleanupRadialMenuTooltip",
        # 窗口控制相关
        "CmdRunSilent": "RunCommandSilently",
        "CompileMouseAndRun": "CompileMouseScriptAndRun",
        "CheckExe": "CheckMouseExeExists",
        "IsCurWinAndMax": "IsCurrentWindowMaximized",
        "RemoteDesktopActiveOrRButtonPressed": "IsRemoteDesktopActiveOrRBtnPressed",
        "IsDoubleClick": "IsDoubleClickEvent",
        "ToggleToOExe": "ToggleOrRunOExe",
        "GetWkSw": "GetWkSwFilePath",
        "WinWaitActivate": "WaitForWindowAndActivate",
        "ActivateMstscExe": "ActivateRemoteDesktopExe",
        "MyWinActivate": "TryActivateWindow",
        "ActivateWXWorkExe": "ActivateWXWorkApp",
        "JumpOutSideOffMsTsc": "ExitRemoteDesktopFullscreenMode",
        "ActivateExistedSel": "ActivateSelectedWindowFromList",
        "ActivateExisted": "TryActivateExistingWindow",
        "ActivateOrRun": "ActivateOrLaunchWindow",
        "RestoreClipboard": "RestoreOriginalClipboard",
        "RunInWinR": "LaunchAppViaWinRDialog",
        "ActivateOrRunInWinR": "ActivateOrLaunchViaWinRDialog",
        "GetDesktopClass": "GetDesktopWindowClass",
        "ActivateTargetWindow": "ActivateCapturedWindow",
        "ToggleTargetWindowTopmost": "ToggleCapturedWindowTopmost",
        "MinimizeTargetWindow": "MinimizeCapturedWindow",
        "ToggleTargetWindowMaximize": "ToggleCapturedWindowMaximize",
        "ClickAtTargetPosition": "ClickAtCapturedMousePos",
        "TransparencyDown": "DecreaseWindowOpacity",
        "TransparencyUp": "IncreaseWindowOpacity",
        # 菜单模式相关
        "EnterMenuMode": "EnterMenuOperationMode",
        "ExitMenuMode": "ExitMenuOperationMode",
        "RegisterMenuHotkeys": "RegisterMenuSpecificHotkeys",
        "UnregisterAllMenuHotkeys": "UnregisterAllMenuHotkeys",  # 无需修改
        "ShowMenuTooltip": "ShowMenuOperationTooltip",
        "HandleMenuHotkey": "HandleMenuHotkeyPress",
        "SwitchMenu": "SwitchToTargetMenuType",
        # 操作模式相关
        "InitializeNormalModeActions": "InitNormalOperationModeActions",
        "ModeActionsSetDo": "SetOperationModeActions",
        "ModeActionsSet": "SetAndNotifyOperationMode",
        "EnterNormalMode": "SwitchToNormalOperationMode",
        "RButtonDo": "PrepareAndShowRadialMenu",
        "EnterWindowActivateMode": "EnterWindowActivationMode",
        "SwitchWindow": "SwitchToWindowInList",
        "SetWindowsOpacity": "SetTargetWindowsOpacity",
        "RestoreAllWindowsOpacity": "RestoreAllWindowsOriginalOpacity",
        "ResetOpacityTimer": "ResetWindowOpacityRestoreTimer",
        "GetWindowsAtMousePos": "GetWindowsUnderCursorPos",
        "SwitchToWindow": "SwitchToTargetWindow",
        "ActivateWindowSafely": "SafelyActivateTargetWindow",
        "SimulateAltTab": "SimulateAltTabToTargetWindow",
        "IsPointInWindowOptimized": "IsPointWithinWindowBounds",
        "EnterWindowControlMode": "EnterBasicWindowControlMode",
        "ProcessWindowResizing": "ProcessBasicWindowResizing",
        "ProcessWindowMovement": "ProcessBasicWindowMovement",
        "EnterWindowControlMode2": "EnterEnhancedWindowControlMode",
        "GetScreenWorkArea": "GetScreenWorkAreaBounds",
        "ProcessWindowResizing2": "ProcessEnhancedWindowResizing",
        "ProcessWindowMovement2": "ProcessEnhancedWindowMovement",
        "EnterWindowKillMode": "EnterWindowCloseKillMode",
    }

    # --------------------------
    # 2. 读取原 AHK 文件内容（UTF-8 编码，避免中文乱码）
    # --------------------------
    try:
        with open(original_ahk_path, "r", encoding="utf-8") as f:
            ahk_content = f.read()
        print(f"✅ 成功读取原文件：{original_ahk_path}")
    except FileNotFoundError:
        print(f"❌ 原文件不存在：{original_ahk_path}")
        return
    except Exception as e:
        print(f"❌ 读取文件失败：{str(e)}")
        return

    # --------------------------
    # 3. 执行替换（先替换变量，再替换函数，避免冲突）
    # --------------------------
    # 3.1 替换变量名（用正则 \b 确保是独立标识符，不替换字符串中的内容）
    for old_var, new_var in var_replacements.items():
        # 匹配规则：变量名前后是单词边界（非字母/数字/下划线），避免部分匹配
        pattern = re.compile(re.escape(old_var), re.UNICODE)
        ahk_content = pattern.sub(new_var, ahk_content)
        print(f"🔄 变量替换：{old_var} → {new_var}")

    # 3.2 替换函数名（同样用单词边界匹配，兼容函数定义/调用场景）
    for old_func, new_func in func_replacements.items():
        pattern = re.compile(re.escape(old_func), re.UNICODE)
        ahk_content = pattern.sub(new_func, ahk_content)
        print(f"🔄 函数替换：{old_func} → {new_func}")

    # --------------------------
    # 4. 写入优化后的 AHK 文件
    # --------------------------
    try:
        # 确保输出目录存在
        output_dir = Path(output_ahk_path).parent
        output_dir.mkdir(parents=True, exist_ok=True)

        with open(output_ahk_path, "w", encoding="utf-8") as f:
            f.write(ahk_content)
        print(f"\n✅ 优化完成！输出文件：{output_ahk_path}")
    except Exception as e:
        print(f"❌ 写入文件失败：{str(e)}")
        return


# --------------------------
# 5. 运行入口（需手动修改原文件路径）
# --------------------------
if __name__ == "__main__":
    # 请替换为你的原 AHK 文件路径和期望的输出路径
    cur_dir = os.path.dirname(__file__)  # 当前文件所在目录
    os.chdir(cur_dir)
    ORIGINAL_AHK_PATH = "merged_files.ahk"  # 原 AHK 文件
    OUTPUT_AHK_PATH = "renamed_merged_files.ahk"  # 优化后输出文件

    # 执行优化
    optimize_ahk_naming(ORIGINAL_AHK_PATH, OUTPUT_AHK_PATH)
