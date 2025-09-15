local function async_run_command(cmd, output_file, callback)
  -- 确保输出文件所在目录存在
  local dir = vim.fn.fnamemodify(output_file, ":h")
  if not vim.fn.isdirectory(dir) then
    vim.fn.mkdir(dir, "p")
  end
  -- 分割命令和参数
  local cmd_parts = {}
  for part in string.gmatch(cmd, "%S+") do
    table.insert(cmd_parts, part)
  end
  local cmd_name = table.remove(cmd_parts, 1)
  -- 创建输出文件（使用libuv API而非Lua的io库）
  local fd = vim.loop.fs_open(output_file, "w", 438) -- 438是0666权限
  if not fd then
    vim.notify("无法创建输出文件: " .. output_file, vim.log.levels.ERROR)
    return
  end
  -- 创建管道用于重定向输出
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  -- 异步执行系统命令
  local handle, pid
  handle, pid = vim.loop.spawn(cmd_name, {
    args = cmd_parts,
    stdio = {nil, stdout, stderr} -- 正确的uv_stream类型
  }, function(code, signal)
    -- 命令执行完成后的清理工作
    stdout:close()
    stderr:close()
    vim.loop.fs_close(fd)
    if handle then handle:close() end
    -- 通知用户命令已完成
    vim.notify(string.format("命令 '%s' 已完成 (退出码: %d)", cmd, code), vim.log.levels.INFO)
    -- 执行回调函数，传入输出文件路径
    if type(callback) == "function" then
      callback(output_file, code, signal)
    end
  end)
  if not handle then
    stdout:close()
    stderr:close()
    vim.loop.fs_close(fd)
    vim.notify("无法执行命令: " .. cmd, vim.log.levels.ERROR)
    return
  end
  -- 将输出重定向到文件
  stdout:read_start(function(err, data)
    if data then
      vim.loop.fs_write(fd, data, nil, function() end)
    end
  end)
  -- 将错误输出也重定向到文件
  stderr:read_start(function(err, data)
    if data then
      vim.loop.fs_write(fd, data, nil, function() end)
    end
  end)
  -- 显示命令开始执行的信息
  vim.notify("正在执行命令: " .. cmd, vim.log.levels.INFO)
end

-- 示例用法
local function process_result(output_file, exit_code)
  vim.schedule(function()
    vim.notify("命令输出已保存到: " .. output_file, vim.log.levels.INFO)
    -- 可以打开文件查看结果：vim.cmd("edit " .. output_file)
  end
end

-- 执行 git status 并在完成后调用 process_result
async_run_command("git status", [[C:\Users\depei_liu\Dp1\temp\temp.txt]], process_result)
