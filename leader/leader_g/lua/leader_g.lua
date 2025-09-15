local G = {}

local function get_py(py)
  local info = debug.getinfo(1, 'S')
  local relative_path = info.source:sub(2)
  relative_path = require 'f'.rep(relative_path)
  return vim.fn.fnamemodify(relative_path, ':p:h:h') .. '\\py\\' .. py
end

function G.add_commit_push_file(file)
  if not require 'f'.is_file_exists(file) then
    return
  end
  local git_add_commit_push_py = get_py '01-git-add-commit-push.py'
  require 'f'.run_and_silent('python %s %s', git_add_commit_push_py, file)
end

function G.add_commit_push_infos(infos)
  if not require 'f'.is(infos) then
    return
  end
  infos = require 'f'.to_table(infos)
  require 'f'.write_lines_to_file(infos, TempTxt)
  G.add_commit_push_file(TempTxt)
end

function G.write_TempTxt_and_quit_and_add_commit_push()
  require 'f'.write_lines_to_file({}, TempTxt)
  require 'f'.cmd('bw %s', TempTxt)
  require 'f'.cmd('silent w! %s', TempTxt)
  if not require 'f'.is(require 'f'.is_cur_last_win()) then
    vim.cmd 'silent q'
  end
  for _ = 1, 1000 do
    local lines = require 'f'.read_lines_from_file(TempTxt)
    if #lines > 0 then
      break
    end
  end
  G.add_commit_push_file(TempTxt)
end

function G.add_commit_push_edit_status()
  require 'f'.async_run_command("git status", TempTxt, function()
    vim.schedule(function()
      vim.cmd 'new'
      local status = require 'f'.read_lines_from_file(TempTxt)
      for i = 1, #status do
        status[i] = '# ' .. status[i]
      end
      vim.fn.setline('.', status)
      vim.cmd 'norm G'
      vim.keymap.set({ 'n', 'v', }, '<cr><cr>', function() G.write_TempTxt_and_quit_and_add_commit_push() end, { desc = 'write_TempTxt_and_quit_and_add_commit_push', buffer = vim.fn.bufnr(), })
    end)
  end)
end

function G.add_commit_push_edit()
  vim.cmd 'new'
  vim.keymap.set({ 'n', 'v', }, '<cr><cr>', function() G.write_TempTxt_and_quit_and_add_commit_push() end, { desc = 'write_TempTxt_and_quit_and_add_commit_push', buffer = vim.fn.bufnr(), })
end

function G.add_commit_push_yank()
  require 'f'.write_lines_to_file(require 'f'.yank_to_lines_table(), TempTxt)
  G.add_commit_push_file(TempTxt)
end

function G.reset_hunk()
  require 'gitsigns'.reset_hunk()
end

function G.reset_hunk_v()
  require 'gitsigns'.reset_hunk { vim.fn.line '.', vim.fn.line 'v', }
end

function G.git_reset_buffer()
  require 'gitsigns'.reset_buffer()
end

function G.pull()
  require 'f'.async_run('git pull')
end

function G.log()
  require 'f'.async_run('git log --oneline')
end

return G
