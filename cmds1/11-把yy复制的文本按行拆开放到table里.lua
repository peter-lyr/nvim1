local function yank_to_lines_table()
  -- 获取默认寄存器（""）中yy复制的内容
  -- 注：yy复制的内容会存入默认寄存器
  local yank_content = vim.fn.getreg('"')
  -- 按换行符拆分内容（处理空行和尾部换行）
  local lines = {}
  -- 遍历所有非空行（若需保留空行，用 '([^\n]*)\n?' 模式）
  for line in string.gmatch(yank_content, '([^\n]*)\n?') do
    table.insert(lines, line)
  end
  -- 处理最后可能的空行（如果原始内容以换行结尾，会多一个空元素）
  if #lines > 0 and lines[#lines] == '' then
    table.remove(lines)
  end
  return lines
end

-- 示例用法
-- 1. 先用 yy 复制一行或多行文本
-- 2. 调用函数获取行table
local lines = yank_to_lines_table()
print(#lines, vim.inspect(lines))  -- 打印结果查看
