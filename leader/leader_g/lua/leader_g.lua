local G = {}

local function get_current_file_path()
  local info = debug.getinfo(1, "S")
  local relative_path = info.source:sub(2)
  local absolute_path = vim.fn.fnamemodify(relative_path, ":p")
  return absolute_path
end

local function get_py(py)
  local info = debug.getinfo(1, "S")
  local relative_path = info.source:sub(2)
  relative_path = require 'f'.rep(relative_path)
  return vim.fn.fnamemodify(relative_path, ":p:h:h") .. '\\py\\' .. py
end

function G.add_commit_push(infos)
  local git_add_commit_push_py = get_py('01-git-add-commit-push.py')
  if not require 'f'.is(infos) then
    return
  end
  infos = require 'f'.to_table(infos)
  require 'f'.write_lines_to_file(infos, TempTxt)
  require 'f'.printf('%s %s', git_add_commit_push_py, TempTxt)
  require 'f'.run_and_pause('python %s %s', git_add_commit_push_py, TempTxt)
end

G.add_commit_push({'01-git-add-commit-push.py'})

return G
