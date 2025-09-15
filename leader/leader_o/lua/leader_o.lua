local O = {}

local w = vim.fn.expand '$HOME' .. '\\w'

function O.open_work_md()
  require 'f'.jump_or_split(w .. '\\work.md')
end

function O.open_init_lua()
  require 'f'.jump_or_split(Nvim1 .. '\\init.lua')
end

function O.open_temp_txt()
  require 'f'.jump_or_split(TempTxt)
end

function O.open_temp_txt_txt()
  require 'f'.jump_or_split(TempTxt .. '.txt')
end

function O.open_stdout_txt()
  require 'f'.jump_or_split(StdOutTxt)
end

function O.open_cur_dir()
  require 'f'.run_and_silent('explorer "%s"', require 'f'.get_parent())
end

function O.open_cwd()
  require 'f'.run_and_silent('explorer "%s"', vim.loop.cwd())
end

return O
