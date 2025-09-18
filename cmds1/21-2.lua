-- lua如何根据窗口名获取它的pid？
-- 废弃，不好用

local function get_pid_by_window_title(window_title_pattern)
	-- 转义窗口标题中的特殊字符（如引号、反斜杠等），避免PowerShell解析错误
	local escaped_title = window_title_pattern:gsub('"', '\\"'):gsub("\\", "\\\\"):gsub("%$", "\\$")

	-- 构建PowerShell命令：根据窗口标题匹配进程，返回PID
	-- 注意：-match 支持正则表达式，可模糊匹配窗口标题
	local ps_cmd = string.format(
		[[
    powershell -Command "$process = Get-Process | Where-Object { $_.MainWindowTitle -match '%s' }; $process.Id"
  ]],
		escaped_title
	)
	-- print(ps_cmd)

	-- 执行PowerShell命令并获取输出
	local handle = io.popen(ps_cmd)
	local output = handle:read("*a")
	handle:close()

	-- 从输出中提取PID（可能返回多个，取第一个有效数字）
	local pid = tonumber(output:match("%d+"))
	return pid
end

-- 使用示例
-- 1. 获取记事本窗口的PID（窗口标题通常包含"无标题 - 记事本"）
local notepad_pid = get_pid_by_window_title("周报旧项目归属参考20250808.xlsx - WPS Office")
if notepad_pid then
	print("记事本窗口的PID: " .. notepad_pid)
else
	print("未找到记事本窗口")
end
