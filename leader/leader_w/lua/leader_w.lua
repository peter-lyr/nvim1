local W = {}

function W.window_go(dir)
	require("f").cmd("wincmd %s", dir)
end

function W.window_delete(dir)
	if dir then
		local wid = vim.fn.win_getid()
		W.window_go(dir)
		if wid ~= vim.fn.win_getid() then
			vim.cmd("q")
		end
		vim.fn.win_gotoid(wid)
	else
		if not require("f").is(require("f").is_cur_last_win()) then
			vim.cmd("q")
		end
	end
end

function W.tabclose()
	vim.cmd([[
    try
      tabclose
    catch
    endtry
  ]])
end

function W.get_cur_bname()
	local bname = require("f").rep_slash(vim.fn.bufname())
	local tail = vim.fn.fnamemodify(bname, ":t")
	vim.fn.timer_start(40, function()
		local col = #tail
		require("f").feed_keys([[\<c-f>]])
		if vim.fn.mode() ~= "n" then
			require("f").feed_keys([[\<esc>]])
		end
		require("f").feed_keys(tostring(col - 1) .. "h")
	end)
	return bname
end

function W.new_empty_file()
	local bname = W.get_cur_bname()
	if not require("f").is(bname) then
		return
	end
	vim.ui.input({ prompt = "new_empty_file: ", default = bname }, function(file_path)
		if file_path then
			require("f").cmd("e %s", file_path)
			require("f").cmd("w %s", file_path)
		end
	end)
end

function W.copy_cur_file()
	local bname = W.get_cur_bname()
	if not require("f").is(bname) then
		return
	end
	vim.ui.input({ prompt = "copy_cur_file: ", default = bname }, function(file_path)
		if file_path then
			require("f").cmd("w %s", file_path)
			require("f").cmd("e %s", file_path)
		end
	end)
end

-- function W.new_win_finc_do(new)
--   local bname = require 'f'.rep_slash(vim.fn.bufname())
--   local head = vim.fn.fnamemodify(bname, ':h')
--   local col = #head + 2
--   vim.cmd(new)
--   vim.fn.setline(1, bname)
--   require 'f'.cmd('norm 0%sl', col)
--   vim.fn.setpos('.', { 0, 1, col, })
-- end
--
-- function W.new_win_finc_down()
--   W.new_win_finc_do 'new'
-- end
--
-- function W.new_win_finc_up()
--   W.new_win_finc_do 'leftabove new'
-- end
--
-- function W.new_win_finc_left()
--   W.new_win_finc_do 'leftabove vnew'
-- end
--
-- function W.new_win_finc_right()
--   W.new_win_finc_do 'vnew'
-- end

function W.win_max_height()
	if vim.api.nvim_get_option_value("winfixheight", { win = vim.fn.win_getid() }) == true then
		return
	end
	local cur_winnr = vim.fn.winnr()
	local cur_wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
	local cur_start_col = cur_wininfo["wincol"]
	local cur_end_col = cur_start_col + cur_wininfo["width"]
	local winids = {}
	local winids_dict = {}
	for winnr = 1, vim.fn.winnr("$") do
		local wininfo = vim.fn.getwininfo(vim.fn.win_getid(winnr))[1]
		local start_col = wininfo["wincol"]
		local end_col = start_col + wininfo["width"]
		if start_col > cur_end_col or end_col < cur_start_col then
		else
			local winid = vim.fn.win_getid(winnr)
			if winnr ~= cur_winnr and vim.api.nvim_get_option_value("winfixheight", { win = winid }) == true then
				winids[#winids + 1] = winid
				winids_dict[winid] = wininfo["height"]
			end
		end
	end
	vim.cmd("wincmd _")
	for _, winid in ipairs(winids) do
		vim.api.nvim_win_set_height(winid, winids_dict[winid] + (#vim.o.winbar > 0 and 1 or 0))
	end
end

function W.win_max_width()
	if vim.api.nvim_get_option_value("winfixwidth", { win = vim.fn.win_getid() }) == true then
		return
	end
	local cur_winnr = vim.fn.winnr()
	local winids = {}
	local winids_dict = {}
	for winnr = 1, vim.fn.winnr("$") do
		local wininfo = vim.fn.getwininfo(vim.fn.win_getid(winnr))[1]
		local winid = vim.fn.win_getid(winnr)
		if winnr ~= cur_winnr and vim.api.nvim_get_option_value("winfixwidth", { win = winid }) == true then
			winids[#winids + 1] = winid
			winids_dict[winid] = wininfo["width"]
		end
	end
	vim.cmd("wincmd |")
	for _, winid in ipairs(winids) do
		vim.api.nvim_win_set_width(winid, winids_dict[winid])
	end
end

function W.bw_all_buffer()
	local all_bnrs = require("f").get_bufs()
	local cnt = 0
	local s = ""
	for _, bnr in ipairs(all_bnrs) do
		cnt = cnt + 1
		s = s .. bnr .. " "
		require("f").cmd("bw %d", bnr)
	end
	require("f").printf("%d buffers bw!: %s", cnt, s)
end

function W.bw_all_unseen_buffer()
	local win_bnrs = require("f").get_all_win_buf_nrs()
	local all_bnrs = require("f").get_bufs()
	-- local bw_bnrs = {}
	local cnt = 0
	local s = ""
	for _, bnr in ipairs(all_bnrs) do
		if not require("f").in_arr(bnr, win_bnrs) then
			local n = require("f").get_tail(vim.fn.bufname(bnr))
			if #n > 0 then
				s = require("f").format("%s [%s]", s, n)
			end
			require("f").cmd("bw %d", bnr)
			cnt = cnt + 1
			-- require 'f'.put(bw_bnrs, bnr)
		end
	end
	require("f").printf("%d buffers bw!: %s", cnt, s)
	-- vim.print(win_bnrs)
	-- vim.print(bw_bnrs)
	-- vim.print(all_bnrs)
end

function W.bw_all_unseen_buffer_other_tab()
	local win_bnrs = require("f").get_win_buf_nrs()
	local all_bnrs = require("f").get_bufs()
	local cnt = 0
	local s = ""
	for _, bnr in ipairs(all_bnrs) do
		if not require("f").in_arr(bnr, win_bnrs) then
			local n = require("f").get_tail(vim.fn.bufname(bnr))
			if #n > 0 then
				s = require("f").format("%s [%s]", s, n)
			end
			require("f").cmd("bw %d", bnr)
			cnt = cnt + 1
		end
	end
	require("f").printf("%d buffers bw!: %s", cnt, s)
end

function W.cycle_notify_windows()
	if not _G.notify_win_index then
		_G.notify_win_index = 0
	end
	local notify_wins = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.api.nvim_buf_get_option(buf, "filetype") == "notify" then
			table.insert(notify_wins, win)
		end
	end
	if #notify_wins == 0 then
		require("f").fidget_notify("No notify windows found")
		return false
	end
	if #notify_wins == 1 then
		vim.api.nvim_set_current_win(notify_wins[1])
		_G.notify_win_index = 1
		return true
	end
	if _G.notify_win_index <= 0 or _G.notify_win_index > #notify_wins then
		_G.notify_win_index = 1
	else
		_G.notify_win_index = _G.notify_win_index % #notify_wins + 1
	end
	vim.api.nvim_set_current_win(notify_wins[_G.notify_win_index])
	return true
end

return W
