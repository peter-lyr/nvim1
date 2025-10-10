local F = {}

function F.is(val)
	if not val or val == 0 or val == "" or val == false or val == {} then
		return nil
	end
	return 1
end

function F.is_number(text)
	return tonumber(text)
end

function F.is_bnr_valid(bnr)
	vim.g.file = nil
	vim.g.bnr = bnr
	vim.cmd([[
    try
      let g:file = nvim_buf_get_name(g:bnr)
    catch
    endtry
  ]])
	return vim.g.file
end

function F.is_buf_modifiable(bnr)
	return not F.is_bnr_valid(bnr) or F.is(vim.bo[bnr].modifiable)
end

function F.is_cur_last_win()
	if vim.fn.tabpagenr("$") > 1 then
		return nil
	end
	return #F.get_win_buf_modifiable_nrs() <= 1 and 1 or nil
end

function F.in_arr(item, tbl)
	return F.is(vim.tbl_contains(tbl, item))
end

function F.in_str(item, str)
	return string.match(str, item)
end

function F.is_term(file)
	return F.in_str("term://", file) or F.in_str("term:\\\\", file)
end

function F.inc_file_tail(bname)
	bname = F.rep_slash(bname)
	local head = vim.fn.fnamemodify(bname, ":h")
	local tail = vim.fn.fnamemodify(bname, ":t")
	local items = vim.fn.split(tail, "-")
	items = vim.fn.reverse(items)
	local len = 0
	for i, item in ipairs(items) do
		local v = F.is_number(item)
		local format = F.format("%%0%dd", #item)
		vim.g.temp_timestamp = item
		vim.g.temp_date = -1
		vim.cmd([[
      try
        let g:temp_date = msgpack#strptime('%Y%m%d', g:temp_timestamp)
      catch
        echomsg 'wwwwwwwww'
      endtry
    ]])
		if v then
			if vim.g.temp_date < 0 then
				items[i] = F.format(format, F.inc(v))
				break
			end
		end
		len = len + #item + 1
	end
	items = vim.fn.reverse(items)
	return F.format("%s%s", head ~= "." and head .. "/" or "", F.join(items, "-")), #bname - len + 1
end

function F.put(arr, item)
	arr[#arr + 1] = item
end

function F.lower(content)
	return vim.fn.tolower(content)
end

function F.get_win_buf_nrs()
	local buf_nrs = {}
	for wnr = 1, vim.fn.winnr("$") do
		buf_nrs[#buf_nrs + 1] = vim.fn.winbufnr(wnr)
	end
	return buf_nrs
end

function F.get_win_buf_modifiable_nrs()
	local buf_nrs = {}
	for bnr in ipairs(F.get_win_buf_nrs()) do
		if F.is(F.is_buf_modifiable(bnr)) then
			F.put(buf_nrs, bnr)
		end
	end
	return buf_nrs
end

function F.cmd(...)
	local cmd = string.format(...)
	local _sta, _ = pcall(vim.cmd, cmd)
	if _sta then
		return cmd
	end
	return nil
end

function F.print(...)
	vim.print(...)
end

function F.printf(...)
	vim.print(string.format(...))
end

function F.format(...)
	return string.format(...)
end

function F.join(arr, sep)
	if not sep then
		sep = "\n"
	end
	return vim.fn.join(arr, sep)
end

function F.rep(content)
	content = string.gsub(content, "/", "\\")
	return content
end

function F.rep_slash(content)
	content = string.gsub(content, "\\", "/")
	return content
end

function F.get_bufs()
	return vim.api.nvim_list_bufs()
end

function F.feed_keys(keys)
	F.cmd(
		[[
    try
      call feedkeys("%s")
    catch
    endtry
  ]],
		keys
	)
end

function F.set_ft(ft, bnr)
	if not ft then
		return
	end
	if not bnr then
		bnr = vim.fn.bufnr()
	end
	vim.bo[bnr].filetype = ft
end

function F.aucmd(event, desc, opts)
	opts = vim.tbl_deep_extend("force", opts, {
		group = vim.api.nvim_create_augroup(desc, {}),
		desc = desc,
	})
	return vim.api.nvim_create_autocmd(event, opts)
end

function F.lazy_load(plugin)
	F.cmd("Lazy load %s", plugin)
end

function F.project_cd()
	F.lazy_load("vim-projectroot")
	vim.cmd([[
    try
      if &ft != 'help'
        ProjectRootCD
      endif
    catch
    endtry
  ]])
end

function F.getlua(luafile)
	local loaded = string.match(F.rep(luafile), ".+lua\\(.+)%.lua")
	if not loaded then
		return nil
	end
	loaded = string.gsub(loaded, "\\", ".")
	return loaded
end

function F.get_lua_plugin(luafile)
	local parts = {}
	for part in string.gmatch(luafile, "[^\\]+") do
		table.insert(parts, part)
	end
	local last_lua_index = nil
	for i = #parts, 1, -1 do
		if parts[i] == "lua" then
			if i < #parts then
				last_lua_index = i
				break
			end
		end
	end
	if last_lua_index then
		parts[last_lua_index] = "plugin"
	end
	return table.concat(parts, "\\"), last_lua_index
end

function F.get_plugin_lua(luafile)
	local parts = {}
	for part in string.gmatch(luafile, "[^\\]+") do
		table.insert(parts, part)
	end
	local last_lua_index = nil
	for i = #parts, 1, -1 do
		if parts[i] == "plugin" then
			if i < #parts then
				last_lua_index = i
				break
			end
		end
	end
	if last_lua_index then
		parts[last_lua_index] = "lua"
	end
	return table.concat(parts, "\\"), last_lua_index
end

function F.get_bnr_file(bnr)
	return F.rep(vim.api.nvim_buf_get_name(bnr))
end

function F.get_cur_file()
	return F.get_bnr_file(0)
end

function F.get_tail(file)
	if not file then
		file = F.get_cur_file()
	end
	return vim.fn.fnamemodify(file, ":t")
end

function F.put_uniq(arr, item)
	if not F.in_arr(item, arr) then
		F.put(arr, item)
	end
end

function F.merge_tables(...)
	local result = {}
	for _, t in ipairs({ ... }) do
		for _, v in ipairs(t) do
			F.put_uniq(result, v)
		end
	end
	return result
end

function F.get_all_win_buf_nrs()
	local buf_nrs = {}
	for i = 1, vim.fn.tabpagenr("$") do
		local bufs = vim.fn.tabpagebuflist(i)
		if #bufs > 0 then
			buf_nrs = F.merge_tables(buf_nrs, bufs)
		end
	end
	return buf_nrs
end

function F.get_proj(file)
	local proj = ""
	F.lazy_load("vim-projectroot")
	if file and F.in_str("diffview://", file) then
		file = string.gsub(file, "^diffview://", "")
	end
	if file then
		_, proj = pcall(vim.fn["ProjectRootGet"], file)
	else
		_, proj = pcall(vim.fn["ProjectRootGet"])
	end
	return F.rep(proj)
end

function F.new_file(file)
	return require("plenary.path"):new(F.rep(file))
end

function F.escape_space(text)
	text = string.gsub(text, " ", "\\ ")
	return text
end

function F.get_parent(file)
	if not file then
		file = F.get_cur_file()
	end
	return F.new_file(file):parent().filename
end

function F.trim(text)
	return vim.fn.trim(text)
end

function F.is_file_exists(file)
	file = vim.fn.trim(file)
	if #file == 0 then
		return nil
	end
	local fp = F.new_file(file)
	if fp:exists() then
		return fp
	end
	return nil
end

function F.is_file(file)
	local fp = F.is_file_exists(F.rep(file))
	if fp and fp:is_file() then
		return 1
	end
	return nil
end

function F.is_dir(file)
	local fp = F.is_file_exists(F.rep(file))
	if fp and fp:is_dir() then
		return 1
	end
	return nil
end

function F.jump_or_split(file, no_split)
	if not file then
		return
	end
	if type(file) == "number" then
		if F.is_bnr_valid(file) then
			file = vim.g.file
		else
			return
		end
	end
	file = F.rep(file)
	if F.is_dir(file) then
		-- F.lazy_load("nvim-tree.lua")
		-- vim.cmd("wincmd s")
		F.cmd("e %s", file)
		return
	end
	local file_proj = F.get_proj(file)
	local jumped = nil
	for winnr = vim.fn.winnr("$"), 1, -1 do
		local bufnr = vim.fn.winbufnr(winnr)
		local fname = F.rep(F.get_bnr_file(bufnr))
		if F.lower(file) == F.lower(fname) and (F.is_file_exists(fname) or F.is_term(fname)) then
			vim.fn.win_gotoid(vim.fn.win_getid(winnr))
			jumped = 1
			break
		end
	end
	if not jumped then
		for winnr = vim.fn.winnr("$"), 1, -1 do
			local bufnr = vim.fn.winbufnr(winnr)
			local fname = F.rep(F.get_bnr_file(bufnr))
			if F.is_file_exists(fname) then
				local proj = F.get_proj(fname)
				if not F.is(file_proj) or F.is(proj) and F.lower(file_proj) == F.lower(proj) then
					vim.fn.win_gotoid(vim.fn.win_getid(winnr))
					jumped = 1
					break
				end
			end
		end
	end
	if not jumped and not no_split then
		if F.is(F.get_cur_file()) or vim.bo[vim.fn.bufnr()].modified == true then
			vim.cmd("wincmd s")
		end
	end
	F.cmd("e %s", file)
end

function F.edit(file)
	if not file then
		return
	end
	F.cmd("e %s", file)
end

function F.get_ft_bnr(ft)
	if not ft then
		return nil
	end
	for _, buf in ipairs(F.get_win_buf_nrs()) do
		if ft == vim.bo[buf].filetype then
			return buf
		end
	end
end

function F.lazy_map(tbls)
	for _, tbl in ipairs(tbls) do
		local opt = {}
		for k, v in pairs(tbl) do
			if type(k) == "string" and k ~= "mode" then
				opt[k] = v
			end
		end
		local lhs = tbl[1]
		if type(lhs) == "table" then
			for _, l in ipairs(lhs) do
				vim.keymap.set(tbl["mode"], l, tbl[2], opt)
			end
		else
			vim.keymap.set(tbl["mode"], lhs, tbl[2], opt)
		end
	end
end

function F.findall(patt, str)
	vim.g.patt = patt
	vim.g.str = str
	vim.g.res = {}
	vim.cmd([[
    python << EOF
import re
import vim
try:
  import luadata
except:
  import os
  os.system('pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com luadata')
  import luadata
patt = vim.eval('g:patt')
string = vim.eval('g:str')
res = re.findall(patt, string)
if res:
  new_res = eval(str(res).replace('(', '[').replace(')', ']'))
  new_res = luadata.serialize(new_res, encoding='utf-8', indent=' ', indent_level=0)
  vim.command(f"""lua vim.g.res = {new_res}""")
EOF
  ]])
	return vim.g.res
end

function F.just_get_git_remote_url(proj)
	local remote = ""
	if proj then
		remote = vim.fn.system(string.format("cd %s && git remote -v", proj))
	else
		remote = vim.fn.system("git remote -v")
	end
	local res = F.findall([[\s([^\s]*git.*\.com[^\s]+)\s]], remote)
	if #res >= 1 then
		return res[1]
	end
	return ""
end

function F.find_file(tail)
	if not tail then
		return nil
	end
	local escaped_tail = tail:gsub("%.", "%%."):gsub("%[", "%%["):gsub("%]", "%%]")
	local current_file = vim.api.nvim_buf_get_name(0)
	local current_dir = F.rep_slash(vim.fn.fnamemodify(current_file, ":h"))
	local patterns = {
		current_dir .. "/" .. escaped_tail,
		current_dir .. "/**/" .. escaped_tail,
	}
	for _, pattern in ipairs(patterns) do
		local files = vim.fn.globpath("", pattern, true, true)
		if #files > 0 then
			return files[1]
		end
	end
	local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
	while parent_dir ~= current_dir do
		local files = vim.fn.globpath(parent_dir, tail, true, true)
		if #files > 0 then
			return files[1]
		end
		local other_files = vim.fn.globpath(parent_dir, "*/" .. tail, true, true)
		for _, file in ipairs(other_files) do
			if not vim.startswith(file, current_dir) then
				return file
			end
		end
		current_dir = parent_dir
		parent_dir = vim.fn.fnamemodify(parent_dir, ":h")
	end
	return nil
end

function F.copy_multiple_filenames()
	vim.fn.setreg("w", vim.loop.cwd())
	vim.fn.setreg("a", F.get_cur_file())
	vim.fn.setreg("b", vim.fn.bufname())
	vim.fn.setreg("t", vim.fn.fnamemodify(vim.fn.bufname(), ":t"))
	vim.fn.setreg("e", vim.fn.expand("<cword>"))
	vim.fn.setreg("r", vim.fn.expand("<cWORD>"))
	vim.fn.setreg("i", vim.fn.trim(vim.fn.getline(".")))
	vim.fn.setreg("u", F.just_get_git_remote_url())
	vim.fn.setreg("d", vim.fn.strftime("%Y%m%d"))
end

function F.telescope_cmd_dir(cmd, dir)
	F.lazy_load("telescope")
	if dir then
		F.cmd("Telescope %s cwd=%s", cmd, dir)
		return
	end
	F.cmd("Telescope %s", cmd)
end

function F.prev_hunk()
	if vim.wo.diff then
		vim.cmd([[call feedkeys("[c")]])
		return
	end
	require("gitsigns").prev_hunk()
end

function F.next_hunk()
	if vim.wo.diff then
		vim.cmd([[call feedkeys("]c")]])
		return
	end
	require("gitsigns").next_hunk()
end

function F.read_lines_from_file(file)
	if F.is_file_exists(file) then
		return vim.fn.readfile(file)
	end
	return {}
end

function F.write_lines_to_file(lines, file)
	F.ensure_file_exists(file)
	vim.fn.writefile(lines, file)
end

function F.to_table(any)
	if type(any) ~= "table" then
		return { any }
	end
	return any
end

function F.delete_files(files)
	if not files then
		local file = F.get_cur_file()
		if F.is_file(file) then
			files = { file }
		end
	end
	if not files then
		return
	end
	F.lazy_load("vim-bbye")
	for _, file in ipairs(files) do
		local bnr = vim.fn.bufnr(file)
		if F.is_file_exists(file) then
			if 0 ~= vim.fn.confirm(F.format("Delete %s?", file)) then
				F.cmd("Bwipeout! %d", bnr)
				F.run_and_notify_title("del /f /s", "del /f /s %s", file)
			end
		end
	end
end

function F.execute_out_buffer(cmd)
	local lines = vim.fn.split(vim.fn.trim(vim.fn.execute(cmd)), "\n")
	if #lines == 0 then
		F.printf("No Output cmd: %s", cmd)
		return
	end
	F.jump_or_split(TempTxt)
	vim.cmd("norm ggdG")
	vim.fn.append(vim.fn.line("$"), lines)
end

function F.execute_out()
	vim.ui.input({ prompt = "execute_out: ", default = "ls!" }, function(cmd)
		if cmd then
			F.execute_out_buffer(cmd)
		end
	end)
end

function F.notifications_buffer()
	F.lazy_load("nvim-notify")
	F.execute_out_buffer("Notifications")
end

function F.message_buffer()
	F.execute_out_buffer("message")
end

function F.fidget_buffer()
	F.execute_out_buffer("Fidget history")
end

function F.notify(...)
	F.lazy_load("nvim-notify")
	local info = string.format(...)
	info = string.gsub(info, "\r", "")
	vim.notify(info)
end

function F.fidget_notify(...)
	F.lazy_load("fidget.nvim")
	local info = string.format(...)
	require("fidget").notify(info)
end

function F.yank_to_lines_table()
	local yank_content = vim.fn.getreg('"')
	local lines = {}
	for line in string.gmatch(yank_content, "([^\n]*)\n?") do
		table.insert(lines, line)
	end
	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines)
	end
	return lines
end

function F.ensure_file_exists(file_path)
	local dir_path = vim.fn.fnamemodify(file_path, ":h")
	if not vim.fn.isdirectory(dir_path) then
		vim.fn.mkdir(dir_path, "p")
	end
	if not vim.fn.filereadable(file_path) then
		local file, err = io.open(file_path, "w")
		if file then
			file:close()
		else
			error("failed to touch: " .. file_path .. ", error msg: " .. (err or "unknown error"))
		end
	end
end

function F.filter_control_chars(text)
	if not text then
		return ""
	end
	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		local cleaned_line = line
		cleaned_line = cleaned_line:gsub(string.char(27) .. "%[[%d;%?]*[a-zA-Z]", "")
		cleaned_line = cleaned_line:gsub(string.char(27) .. "%]0;[^" .. string.char(7) .. "]*" .. string.char(7), "")
		cleaned_line = cleaned_line:gsub(string.char(27) .. "%][^" .. string.char(7) .. "]*" .. string.char(7), "")
		cleaned_line = cleaned_line:gsub("[%c%z]", "")
		if cleaned_line:match("%S") then
			table.insert(lines, cleaned_line)
		end
	end
	return table.concat(lines, "\n")
end

function F.async_run(cmd, opts)
	_G.running_jobs = _G.running_jobs or {}
	F.lazy_load("nvim-notify")
	opts = opts or {}
	local use_pty = opts.use_pty ~= nil and opts.use_pty or false
	local interval = opts.interval or 30000
	local output_file = opts.output_file or StdOutTxt
	local fd = nil
	local dir
	local start_time = vim.loop.hrtime()
	if output_file then
		dir = vim.fn.fnamemodify(output_file, ":h")
		if not vim.fn.isdirectory(dir) then
			vim.fn.mkdir(dir, "p")
		end
		fd = vim.loop.fs_open(output_file, "w", 438)
		if not fd then
			F.notify("failed to touch file: " .. output_file, vim.log.levels.ERROR)
			return
		end
	end
	local partial_line = ""
	local stdout_cache = {}
	local timer = nil
	local title = opts.title or "Command Output"
	local function process_cache()
		if partial_line ~= "" then
			table.insert(stdout_cache, partial_line)
			partial_line = ""
		end
		if #stdout_cache == 0 then
			vim.notify("no output", vim.log.levels.INFO, { title = title .. "..." })
			return
		end
		local output = vim.list_slice(stdout_cache)
		stdout_cache = {}
		if fd and #output > 0 then
			local content = table.concat(output, "\n") .. "\n"
			vim.loop.fs_write(fd, content, nil, function() end)
		end
		if #output > 0 then
			local message = table.concat(output, "\n")
			message = string.gsub(message, "\r", "")
			message = F.filter_control_chars(message)
			vim.notify(message, vim.log.levels.INFO, { title = title .. "..." })
			if opts.on_stdout then
				opts.on_stdout(output)
			end
		end
	end
	timer = vim.loop.new_timer()
	if timer then
		timer:start(interval, interval, vim.schedule_wrap(process_cache))
	end
	vim.g.job_id = vim.fn.jobstart(cmd, {
		pty = use_pty,
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = function(_, data, _)
			if not data or vim.tbl_isempty(data) then
				return
			end
			for _, chunk in ipairs(data) do
				local temp = use_pty and "" or "\n"
				local combined = partial_line .. temp .. chunk
				partial_line = ""
				local parts = {}
				local start = 1
				while start <= #combined do
					local pos_n = string.find(combined, "\n", start, true)
					local pos_r = string.find(combined, "\r", start, true)
					local pos = nil
					if pos_n and pos_r then
						pos = math.min(pos_n, pos_r)
					else
						pos = pos_n or pos_r
					end
					if not pos then
						break
					end
					local part = string.sub(combined, start, pos - 1)
					if part ~= "" then
						table.insert(parts, part)
					end
					start = pos + 1
					if start <= #combined then
						local next_char = combined:sub(start, start)
						if next_char == "\n" or next_char == "\r" then
							start = start + 1
						end
					end
				end
				partial_line = string.sub(combined, start)
				for _, part in ipairs(parts) do
					table.insert(stdout_cache, part)
				end
			end
		end,
		on_stderr = function(_, data, _)
			local errors = {}
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(errors, line)
				end
			end
			if fd and #errors > 0 then
				local content = table.concat(errors, "\n") .. "\n"
				vim.loop.fs_write(fd, content, nil, function() end)
			end
			if #errors > 0 then
				local message = table.concat(errors, "\n")
				message = F.filter_control_chars(message)
				vim.notify(message, vim.log.levels.ERROR, { title = title .. " (Error)" })
				if opts.on_stderr then
					opts.on_stderr(errors)
				end
			end
		end,
		on_exit = function(_, exit_code, signal)
			if vim.g.job_id then
				_G.running_jobs[vim.g.job_id] = nil
			end
			local end_time = vim.loop.hrtime()
			local duration_ms = (end_time - start_time) / 1e6
			local duration_sec = duration_ms / 1000
			process_cache()
			if fd then
				vim.loop.fs_close(fd)
			end
			if timer then
				timer:stop()
				timer:close()
				timer = nil
			end
			if duration_sec > 10 then
				local time_message = string.format("Command completed in %.2f seconds", duration_sec)
				vim.notify(time_message, vim.log.levels.INFO, { title = title .. " (Duration)" })
			end
			if opts.on_exit then
				opts.on_exit(exit_code, signal, output_file)
			end
		end,
	})
	if vim.g.job_id <= 0 then
		vim.notify("failed to run " .. vim.inspect(cmd), vim.log.levels.ERROR, { title = "Command Error" })
		if fd then
			vim.loop.fs_close(fd)
		end
		if timer then
			timer:stop()
			timer:close()
			timer = nil
		end
		vim.notify("failed to run " .. vim.inspect(cmd), vim.log.levels.ERROR, { title = "Command Error" })
	else
		_G.running_jobs[vim.g.job_id] = {
			cmd = cmd,
			title = title,
			start_time = start_time,
			output_file = output_file,
		}
		F.fidget_notify("running: " .. cmd, vim.log.levels.INFO)
	end
	return vim.g.job_id
end

function F.kill_all_running_jobs()
	local count = 0
	_G.running_jobs = _G.running_jobs or {}
	for job_id, job_info in pairs(_G.running_jobs) do
		vim.fn.jobstop(job_id)
		count = count + 1
		vim.notify("Killed: " .. job_info.cmd, vim.log.levels.WARN, { title = "Process Manager" })
	end
	_G.running_jobs = {}
	if count == 0 then
		vim.notify("No running jobs to kill", vim.log.levels.INFO, { title = "Process Manager" })
	else
		vim.notify(string.format("Killed %d running job(s)", count), vim.log.levels.WARN, { title = "Process Manager" })
	end
end

function F.show_running_jobs()
	local count = 0
	local job_list = {}
	_G.running_jobs = _G.running_jobs or {}
	for job_id, job_info in pairs(_G.running_jobs) do
		count = count + 1
		local duration = (vim.loop.hrtime() - job_info.start_time) / 1e9
		table.insert(job_list, string.format("Job %d: %s (%.1fs)", job_id, job_info.cmd, duration))
	end
	if count == 0 then
		vim.notify("No running jobs", vim.log.levels.INFO, { title = "Process Manager" })
	else
		local message = string.format("Running jobs (%d):\n%s", count, table.concat(job_list, "\n"))
		vim.notify(message, vim.log.levels.INFO, { title = "Process Manager" })
	end
end

function F.run_and_exit(...)
	local cmd = string.format(...)
	F.cmd([[silent !start cmd /c "%s"]], cmd)
end

function F.run_and_silent(...)
	local cmd = string.format(...)
	F.cmd([[silent !start /b /min cmd /c "%s"]], cmd)
end

function F.run_and_pause(...)
	local cmd = string.format(...)
	F.cmd([[silent !start cmd /c "%s & pause"]], cmd)
end

function F.run_and_notify(...)
	local cmd = string.format(...)
	F.async_run(cmd, { title = cmd })
end

function F.run_and_notify_pty(...)
	local cmd = string.format(...)
	F.async_run(cmd, { title = cmd, use_pty = true, interval = 5000 })
end

function F.run_and_notify_title(title, ...)
	local cmd = string.format(...)
	F.async_run(cmd, { title = title })
end

function F.run_and_notify_title_on_err(title, on_stderr, ...)
	local cmd = string.format(...)
	F.async_run(cmd, { title = title, on_stderr = on_stderr })
end

function F.run_and_notify_title_on_err_pty(title, on_stderr, ...)
	local cmd = string.format(...)
	F.async_run(cmd, { title = title, on_stderr = on_stderr, use_pty = true, interval = 5000 })
end

function F.run_and_notify_title_on_exit(title, on_exit, ...)
	local cmd = string.format(...)
	F.async_run(cmd, { title = title, on_exit = on_exit })
end

function F.ui_input(prompt, default, callback)
	vim.ui.input({ prompt = prompt, default = default }, function(input)
		if input then
			callback(input)
		end
	end)
end

function F.ui_sel(items, opts, callback)
	if type(opts) == "string" then
		opts = { prompt = opts }
	end
	if items and #items > 0 then
		if vim.g.ui_select ~= vim.ui.select then
			require("telescope").load_extension("ui-select")
			vim.g.ui_select = vim.ui.select
		end
		vim.ui.select(items, opts, callback)
	end
end

function F.ui(arr, opts, callback)
	F.lazy_load("telescope.nvim")
	if arr and #arr == 1 then
		callback(arr[1])
	else
		F.ui_sel(arr, opts, function(choose, index)
			if choose then
				callback(choose, index)
			end
		end)
	end
end

function F.windo(...)
	local wid = vim.fn.win_getid(vim.fn.winnr())
	local cmd = string.format(...)
	F.cmd([[windo %s]], cmd)
	vim.fn.win_gotoid(wid)
end

return F
