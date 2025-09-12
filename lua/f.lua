local M         = {}

function M.is(val)
  if not val or val == 0 or val == '' or val == false or val == {} then
    return nil
  end
  return 1
end

function M.is_bnr_valid(bnr)
  vim.g.file = nil
  vim.g.bnr = bnr
  vim.cmd [[
    try
      let g:file = nvim_buf_get_name(g:bnr)
    catch
    endtry
  ]]
  return vim.g.file
end

function M.is_buf_modifiable(bnr)
  return not M.is_bnr_valid(bnr) or M.is(vim.bo[bnr].modifiable)
end

function M.is_cur_last_win()
  if vim.fn.tabpagenr '$' > 1 then
    return nil
  end
  return #M.get_win_buf_modifiable_nrs() <= 1 and 1 or nil
end

function M.put(arr, item)
  arr[#arr + 1] = item
end

function M.get_win_buf_nrs()
  local buf_nrs = {}
  for wnr = 1, vim.fn.winnr '$' do
    buf_nrs[#buf_nrs + 1] = vim.fn.winbufnr(wnr)
  end
  return buf_nrs
end

function M.get_win_buf_modifiable_nrs()
  local buf_nrs = {}
  for bnr in ipairs(M.get_win_buf_nrs()) do
    if M.is(M.is_buf_modifiable(bnr)) then
      M.put(buf_nrs, bnr)
    end
  end
  return buf_nrs
end

function M.cmd(str_format, ...)
  local cmd = string.format(str_format, ...)
  local _sta, _ = pcall(vim.cmd, cmd)
  if _sta then
    return cmd
  end
  return nil
end

return M
