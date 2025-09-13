local O = {}

local w = vim.fn.expand '$HOME' .. '\\w'

function O.open_work_md()
  require 'f'.jump_or_split(w .. '\\work.md')
end

return O

