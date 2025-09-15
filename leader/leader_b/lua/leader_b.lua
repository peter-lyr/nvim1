local B = {}

function B.swap_file()
  if vim.o.ft == 'lua' then
    local file, sta
    local cur_file = require 'f'.get_cur_file()
    file, sta = require 'f'.getluapy(cur_file)
    if sta then
      require 'f'.edit(file)
    else
      file, sta = require 'f'.getpylua(cur_file)
      if sta then
        require 'f'.edit(file)
      end
    end
    return
  end
end

return B
