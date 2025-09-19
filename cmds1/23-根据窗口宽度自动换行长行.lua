-- 对当前文件中的长行进行自动换行
function auto_wrap_long_lines()
	-- 获取当前窗口和缓冲区
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()

	-- 获取当前窗口的列数（宽度）
	local win_width = vim.api.nvim_win_get_width(win)

	-- 计算每行最大字符数（窗口宽度减2）
	local max_chars = win_width - 8
	if max_chars <= 0 then
		vim.notify("窗口宽度过小，无法进行换行")
		return
	end

	-- 获取当前文件的所有行
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local new_lines = {}

	-- 遍历每一行并处理长行
	for _, line in ipairs(lines) do
		-- 如果行长度小于等于最大字符数，直接添加
		if #line <= max_chars then
			table.insert(new_lines, line)
		else
			-- 拆分长行
			local start = 1
			while start <= #line do
				local end_pos = math.min(start + max_chars - 1, #line)
				-- 提取子字符串并添加到新行列表
				table.insert(new_lines, string.sub(line, start, end_pos))
				start = end_pos + 1
			end
		end
	end

	-- 将处理后的内容写回缓冲区
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
	vim.notify(string.format("已完成自动换行，每行最大 %d 个字符", max_chars))
end

-- 示例快捷键：按 <leader>w 触发自动换行
vim.keymap.set("n", "<leader>wz", auto_wrap_long_lines, { desc = "根据窗口宽度自动换行长行" })
