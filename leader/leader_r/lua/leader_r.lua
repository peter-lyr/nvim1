local R = {}

function R.source(luafile)
	if not require("f").is_file_exists(luafile) then
		return
	end
	require("f").printf("source %s", luafile)
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
			R.source(lua_plugin)
		else
			local _pluginlua, _ = require("f").get_plugin_lua(cur_file)
			R.source(_pluginlua)
			R.source(cur_file)
		end
		if require("f").is(lua) then
			package.loaded[lua] = dofile(cur_file)
		end
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

return R
