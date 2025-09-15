local function get_current_file_path()
  local info = debug.getinfo(1, "S")
  local relative_path = info.source:sub(2)
  local absolute_path = vim.fn.fnamemodify(relative_path, ":p")
  return absolute_path
end
print("当前Lua文件路径：", get_current_file_path())
