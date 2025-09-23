local R = {}

local function get_py(py)
	local info = debug.getinfo(1, "S")
	local relative_path = info.source:sub(2)
	relative_path = require("f").rep(relative_path)
	return vim.fn.fnamemodify(relative_path, ":p:h:h") .. "\\py\\" .. py
end

local run_and_get_pid = get_py("01-run-and-get-pid.py")

function R.source(luafile)
	if not require("f").is_file_exists(luafile) then
		return
	end
	require("f").notify(string.format("source %s", luafile))
	require("f").cmd("source %s", luafile)
end

function R.run_cur_file(no_console_window, auto_exit)
	auto_exit = auto_exit and "" or " & pause"
	no_console_window = no_console_window and " /b /min " or ""
	local cur_file = require("f").get_cur_file()
	if not require("f").is_file_exists(cur_file) then
		return
	end
	if vim.o.ft == "lua" then
		local lua = require("f").getlua(cur_file)
		if require("f").is(lua) then
			package.loaded[lua] = nil
		end
		local lua_plugin, sta = require("f").get_lua_plugin(cur_file)
		if sta then
			R.source(cur_file)
			if cur_file ~= lua_plugin then
				R.source(lua_plugin)
			end
		else
			local _pluginlua, _ = require("f").get_plugin_lua(cur_file)
			R.source(_pluginlua)
			if cur_file ~= cur_file then
				R.source(cur_file)
			end
		end
		if require("f").is(lua) then
			package.loaded[lua] = dofile(cur_file)
		end
	elseif vim.o.ft == "autohotkey" then
		require("f").cmd(
			[[silent !start %s cmd /c "python "%s" %s"]],
			no_console_window,
			require("f").find_file("main.ahk"),
			auto_exit
		)
	elseif vim.o.ft == "python" then
		require("f").cmd([[silent !start %s cmd /c "python "%s" %s"]], no_console_window, cur_file, auto_exit)
	else
		require("f").cmd([[silent !start %s cmd /c ""%s" %s"]], no_console_window, cur_file, auto_exit)
	end
end

function R.run_cur_file_silent()
	R.run_cur_file(1)
end

function R.run_cur_file_exit()
	R.run_cur_file(nil, 1)
end

function R.stop_cur_file() end

return R
