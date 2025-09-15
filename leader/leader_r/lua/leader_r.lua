local R = {}

function R.run_and_pause()
  local cur_file = require 'f'.get_cur_file()
  if not require 'f'.is_file_exists(cur_file) then
    return
  end
  if vim.o.ft == 'lua' then
    package.loaded[require 'f'.getlua(require 'f'.get_cur_file())] = nil
    vim.cmd 'source %:p'
  else
    require 'f'.cmd([[silent !start cmd /c "%s & pause"]], cur_file)
  end
end

return R
