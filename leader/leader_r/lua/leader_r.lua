local R = {}

function R.getlua(luafile)
  local loaded = string.match(R.rep(luafile), '.+lua\\(.+)%.lua')
  if not loaded then
    return nil
  end
  loaded = string.gsub(loaded, '\\', '.')
  return loaded
end


function R.get_lua_plugin(luafile)
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

function R.get_plugin_lua(luafile)
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

function R.source(luafile)
  require 'f'.printf('source %s', luafile)
  require 'f'.cmd('source %s', luafile)
end

function R.run_cur_file()
  local cur_file = require 'f'.get_cur_file()
  if not require 'f'.is_file_exists(cur_file) then
    return
  end
  if vim.o.ft == 'lua' then
    local lua = R.getlua(cur_file)
    require 'f'.printf('lua:%s.', lua)
    if require 'f'.is(lua) then
      package.loaded[lua] = nil
    end
    local lua_plugin, sta = R.get_lua_plugin(cur_file)
    if sta then
      R.source(cur_file)
      R.source(lua_plugin)
    else
      local _pluginlua, _ = R.get_plugin_lua(cur_file)
      R.source(_pluginlua)
      R.source(cur_file)
    end
    if require 'f'.is(lua) then
      package.loaded[lua] = dofile(cur_file)
    end
  else
    require 'f'.cmd([[silent !start cmd /c "%s & pause"]], cur_file)
  end
end

return R
