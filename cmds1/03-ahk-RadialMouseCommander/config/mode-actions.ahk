; 模式动作配置

global g_ModeActionMappings := Map()

InitializeModeActionMappings() {
    global g_ModeActionMappings
    normalModeActions := Map()
    normalModeActions["000U"] := ["向上移动光标", Send.Bind("{Up}")]
    normalModeActions["000D"] := ["向下移动光标", Send.Bind("{Down}")]
    normalModeActions["000L"] := ["向左移动光标", Send.Bind("{Left}")]
    normalModeActions["000R"] := ["向右移动光标", Send.Bind("{Right}")]
    normalModeActions["000RU"] := ["切换最大化窗口", ToggleTargetWindowMaximize]
    normalModeActions["000RD"] := ["最小化窗口", MinimizeTargetWindow]
    normalModeActions["000LU"] := ["窗口控制模式", EnterWindowControlMode]
    g_ModeActionMappings["normal"] := normalModeActions
}
