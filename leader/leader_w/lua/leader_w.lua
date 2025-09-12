local W = {}
local F_ = require 'f'

function W.window_go(dir)
  F_.cmd('wincmd %s', dir)
end

function W.window_delete(dir)
  if dir then
    local wid = vim.fn.win_getid()
    W.window_go(dir)
    if wid ~= vim.fn.win_getid() then
      vim.cmd 'q'
    end
    vim.fn.win_gotoid(wid)
  else
    if not F_.is(F_.is_cur_last_win()) then
      vim.cmd 'q'
    end
  end
end

function W.tabclose()
  vim.cmd [[
    try
      tabclose
    catch
    endtry
  ]]
end

return W
