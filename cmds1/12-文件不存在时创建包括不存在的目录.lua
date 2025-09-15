-- 确保文件存在，如果不存在则创建，包括所需的目录结构
local function ensure_file_exists(file_path)
  -- 提取文件所在的目录路径
  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  -- 检查目录是否存在，如果不存在则递归创建
  if not vim.fn.isdirectory(dir_path) then
    -- 使用"p"标志递归创建目录
    vim.fn.mkdir(dir_path, "p")
  end
  -- 检查文件是否存在，如果不存在则创建空文件
  if not vim.fn.filereadable(file_path) then
    -- 以写入模式打开文件会创建新文件
    local file, err = io.open(file_path, "w")
    if file then
      file:close()  -- 关闭文件句柄
    else
      error("无法创建文件: " .. file_path .. "，错误信息: " .. (err or "未知错误"))
    end
  end
end

-- 示例用法：
ensure_file_exists("c:/path/to/your/directory/file.txt")
