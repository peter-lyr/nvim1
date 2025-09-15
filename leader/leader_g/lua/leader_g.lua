local G = {}

local function get_py(py)
  local info = debug.getinfo(1, "S")
  local relative_path = info.source:sub(2)
  relative_path = require 'f'.rep(relative_path)
  return vim.fn.fnamemodify(relative_path, ":p:h:h") .. '\\py\\' .. py
end

function G.add_commit_push_file(file)
  if not require 'f'.is_file_exists(file) then
    return
  end
  local git_add_commit_push_py = get_py('01-git-add-commit-push.py')
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
  require 'f'.cmd('w! %s', TempTxt)
  vim.cmd('q')
  for i=1, 1000 do
    local lines = require 'f'.read_lines_from_file(TempTxt)
    if #lines > 0 then
      break
    end
  end
  G.add_commit_push_file(TempTxt)
end

function G.add_commit_push_edit_status()
  vim.cmd 'new'
  local status = vim.fn.execute('!git status')
  status = vim.fn.split(status, '\n')
  for i=1, #status do
    status[i] = '# ' .. status[i]
  end
  vim.fn.setline('.', status)
  vim.cmd 'norm G'
  vim.keymap.set({ 'n', 'v', }, '<cr><cr>', function() G.write_TempTxt_and_quit_and_add_commit_push() end, { desc = 'add_commit_push_edit_status', buffer = vim.fn.bufnr(), })
end

return G
