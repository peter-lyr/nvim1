local O = {}

local w = vim.fn.expand '$HOME' .. '\\w'

function O.open_work_md()
  require 'f'.jump_or_split(w .. '\\work.md')
end

function O.open_init_lua()
  require 'f'.jump_or_split(Nvim1 .. '\\init.lua')
end

return O
