local R = {}

function R.run_and_pause()
  local cur_file = require 'f'.get_cur_file()
  if not require 'f'.is_file_exists(cur_file) then
    return
  end
  if vim.o.ft == 'lua' then
    local lua = require 'f'.getlua(cur_file)
    require 'f'.printf('lua:%s.', lua)
    if require 'f'.is(lua) then
      package.loaded[lua] = nil
    end
    require 'f'.printf('source %s', cur_file)
    require 'f'.printf('source %s', require 'f'.getluapy(cur_file))
    require 'f'.cmd('source %s', cur_file)
    require 'f'.cmd('source %s', require 'f'.getluapy(cur_file))
    if require 'f'.is(lua) then
      package.loaded[lua] = dofile(cur_file)
    end
  else
    require 'f'.cmd([[silent !start cmd /c "%s & pause"]], cur_file)
  end
end

return R
