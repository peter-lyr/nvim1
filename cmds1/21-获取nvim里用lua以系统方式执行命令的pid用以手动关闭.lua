-- 这个只能找到以某某.exe文件运行程序的pid

local function run_with_pid(no_console_window, cur_file, auto_exit)
	-- 构建要执行的命令（包含用户的程序和参数）
	local program_cmd = string.format([["%s" %s]], cur_file, auto_exit)

	-- 构建PowerShell命令：用Start-Process启动程序并返回PID
	local ps_cmd
	if no_console_window then
		-- 无窗口模式
		ps_cmd = string.format(
			[[
      powershell -Command "$process = Start-Process -FilePath cmd -ArgumentList '/c %s' -NoNewWindow -PassThru; $process.Id"
    ]],
			program_cmd
		)
	else
		-- 有窗口模式
		ps_cmd = string.format(
			[[
      powershell -Command "$process = Start-Process -FilePath cmd -ArgumentList '/c %s' -PassThru; $process.Id"
    ]],
			program_cmd
		)
	end

	-- 执行PowerShell命令并获取PID
	local handle = io.popen(ps_cmd)
	local pid = handle:read("*a")
	handle:close()

	-- 清理并返回PID
	return tonumber(pid:match("%d+"))
end

local function get_child_pid(parent_pid)
	-- 通过父进程PID查询子进程（mouse.exe）的PID
	local ps_cmd = string.format(
		[[
    powershell -Command "$child = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq %d -and $_.Name -eq 'mouse.exe' }; $child.ProcessId"
  ]],
		parent_pid
	)

	local handle = io.popen(ps_cmd)
	local child_pid = handle:read("*a")
	handle:close()

	return tonumber(child_pid:match("%d+"))
end

local function run_and_kill(no_console_window, cur_file, auto_exit)
	-- 启动进程并获取cmd的父进程PID
	local parent_pid = run_with_pid(no_console_window, cur_file, auto_exit) -- 复用之前的run_with_pid函数
	if not parent_pid then
		print("启动进程失败")
		return
	end

	-- 等待子进程启动（根据程序启动速度调整）
	vim.cmd("sleep 1000m")

	-- 获取mouse.exe的子进程PID
	local child_pid = get_child_pid(parent_pid)
	if not child_pid then
		print("未找到子进程mouse.exe")
		return child_pid
	end

	print("子进程mouse.exe的PID: " .. child_pid)
	return child_pid, parent_pid -- 返回子进程和父进程PID，方便后续关闭
end

-- 使用示例：关闭进程时优先关闭子进程
local child_pid, parent_pid = run_and_kill(false, [[mouse.exe]], "")

-- 关闭进程（先关子进程，再关父进程）
if child_pid then
	print(string.format("taskkill /f /pid %d", child_pid)) -- 关闭mouse.exe
	os.execute(string.format("taskkill /f /pid %d", child_pid)) -- 关闭mouse.exe
end
if parent_pid then
	print(string.format("taskkill /f /pid %d", parent_pid)) -- 关闭残留的cmd
	os.execute(string.format("taskkill /f /pid %d", parent_pid)) -- 关闭残留的cmd
end
