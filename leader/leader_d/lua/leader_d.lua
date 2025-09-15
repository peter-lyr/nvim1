local D = {}

function D.delete_cur_file()
  local current_file = vim.fn.expand '%:p'
  if current_file == '' or not vim.loop.fs_stat(current_file) then
    vim.notify('当前缓冲区没有关联文件', vim.log.levels.WARN)
    return
  end
  local msg = string.format('确定要删除文件: %s 吗? [Y/n]', current_file)
  vim.api.nvim_echo({ { msg, 'WarningMsg', }, }, false, {})
  local char = vim.fn.getcharstr()
  if char:lower() == 'y' then
    local ok, err = pcall(vim.loop.fs_unlink, current_file)
    if ok then
      vim.notify(string.format('文件已删除: %s', current_file), vim.log.levels.INFO)
      vim.cmd 'bdelete!'
    else
      vim.notify(string.format('删除失败: %s', err), vim.log.levels.ERROR)
    end
  else
    vim.notify('已取消删除操作', vim.log.levels.INFO)
    vim.cmd "echo ''"  -- 清空命令行提示
  end
end

function D.delete_cur_buffer()
  vim.cmd 'bdelete!'
end

return D
