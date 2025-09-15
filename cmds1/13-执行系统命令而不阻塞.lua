-- 异步执行系统命令，不阻塞Neovim，优化了输出显示
-- 参数:
--   cmd: 要执行的命令字符串或命令数组
--   opts: 可选参数，包含回调函数等配置
--     on_stdout: 处理标准输出的回调函数
--     on_stderr: 处理错误输出的回调函数
--     on_exit: 命令执行完成的回调函数
--     title: 通知标题（可选）
local function async_run(cmd, opts)
  opts = opts or {}
  local title = opts.title or "Command Output"
  -- 使用jobstart异步执行命令
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      -- 过滤空行并合并为一个字符串
      local output = {}
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output, line)
        end
      end
      if #output > 0 then
        local message = table.concat(output, "\n")
        -- 使用vim.notify显示，默认info级别
        vim.notify(message, vim.log.levels.INFO, { title = title })
        -- 如果有自定义回调则执行
        if opts.on_stdout then
          opts.on_stdout(output)
        end
      end
    end,
    on_stderr = function(_, data, _)
      -- 过滤空行并合并为一个字符串
      local errors = {}
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(errors, line)
        end
      end
      if #errors > 0 then
        local message = table.concat(errors, "\n")
        -- 错误信息使用error级别
        vim.notify(message, vim.log.levels.ERROR, { title = title .. " (Error)" })
        -- 如果有自定义回调则执行
        if opts.on_stderr then
          opts.on_stderr(errors)
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      local message = "Command completed with exit code: " .. exit_code
      -- 成功执行用info级别，错误用warn级别
      local level = exit_code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
      vim.notify(message, level, { title = title .. " (Exit)" })
      -- 如果有自定义回调则执行
      if opts.on_exit then
        opts.on_exit(exit_code)
      end
    end,
    -- 确保输出按行缓冲，便于一次性处理
    stdout_buffered = true,
    stderr_buffered = true,
  })
  -- 检查是否成功启动任务
  if job_id <= 0 then
    vim.notify("Failed to start command: " .. vim.inspect(cmd), 
      vim.log.levels.ERROR, { title = "Command Error" })
  end
  return job_id
end

-- 示例用法
async_run("git status", {
  title = "Directory Listing",  -- 自定义通知标题
  -- 可选的自定义回调
  on_exit = function(exit_code)
    if exit_code == 0 then
    end
  end,
  on_stdout = function(data)
    if #data > 0 then
    end
  end,
  on_stderr = function(data)
    if #data > 0 then
    end
  end,
})
