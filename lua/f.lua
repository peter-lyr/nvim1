local F = {}

function F.is(val)
  if not val or val == 0 or val == '' or val == false or val == {} then
    return nil
  end
  return 1
end

function F.is_number(text)
  return tonumber(text)
end

function F.is_bnr_valid(bnr)
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

function F.is_buf_modifiable(bnr)
  return not F.is_bnr_valid(bnr) or F.is(vim.bo[bnr].modifiable)
end

function F.is_cur_last_win()
  if vim.fn.tabpagenr '$' > 1 then
    return nil
  end
  return #F.get_win_buf_modifiable_nrs() <= 1 and 1 or nil
end

function F.in_arr(item, tbl)
  return F.is(vim.tbl_contains(tbl, item))
end

function F.inc_file_tail(bname)
  bname = F.rep_slash(bname)
  local head = vim.fn.fnamemodify(bname, ':h')
  local tail = vim.fn.fnamemodify(bname, ':t')
  local items = vim.fn.split(tail, '-')
  items = vim.fn.reverse(items)
  local len = 0
  for i, item in ipairs(items) do
    local v = F.is_number(item)
    local format = F.format('%%0%dd', #item)
    vim.g.temp_timestamp = item
    vim.g.temp_date = -1
    --- print(item)
    vim.cmd [[
      try
        let g:temp_date = msgpack#strptime('%Y%m%d', g:temp_timestamp)
      catch
        echomsg 'wwwwwwwww'
      endtry
    ]]
    if v then
      if vim.g.temp_date < 0 then
        items[i] = F.format(format, F.inc(v))
        break
      end
    end
    len = len + #item + 1
  end
  items = vim.fn.reverse(items)
  return F.format('%s%s', head ~= '.' and head .. '/' or '', F.join(items, '-')), #bname - len + 1
end

function F.put(arr, item)
  arr[#arr + 1] = item
end

function F.get_win_buf_nrs()
  local buf_nrs = {}
  for wnr = 1, vim.fn.winnr '$' do
    buf_nrs[#buf_nrs + 1] = vim.fn.winbufnr(wnr)
  end
  return buf_nrs
end

function F.get_win_buf_modifiable_nrs()
  local buf_nrs = {}
  for bnr in ipairs(F.get_win_buf_nrs()) do
    if F.is(F.is_buf_modifiable(bnr)) then
      F.put(buf_nrs, bnr)
    end
  end
  return buf_nrs
end

function F.cmd(str_format, ...)
  local cmd = string.format(str_format, ...)
  local _sta, _ = pcall(vim.cmd, cmd)
  if _sta then
    return cmd
  end
  return nil
end

function F.print(...)
  vim.print(...)
end

function F.printf(...)
  vim.print(string.format(...))
end

function F.format(str_format, ...)
  return string.format(str_format, ...)
end

function F.join(arr, sep)
  if not sep then
    sep = '\n'
  end
  return vim.fn.join(arr, sep)
end

function F.rep(content)
  content = string.gsub(content, '/', '\\')
  return content
end

function F.rep_slash(content)
  content = string.gsub(content, '\\', '/')
  return content
end

function F.get_bufs()
  return vim.api.nvim_list_bufs()
end

function F.feed_keys(keys)
  F.cmd([[
    try
      call feedkeys("%s")
    catch
    endtry
  ]], keys)
end

function F.set_ft(ft, bnr)
  if not ft then
    return
  end
  if not bnr then
    bnr = vim.fn.bufnr()
  end
  vim.bo[bnr].filetype = ft
end

function F.aucmd(event, desc, opts)
  opts = vim.tbl_deep_extend(
    'force',
    opts,
    {
      group = vim.api.nvim_create_augroup(desc, {}),
      desc = desc,
    })
  return vim.api.nvim_create_autocmd(event, opts)
end

function F.lazy_load(plugin)
  F.cmd('Lazy load %s', plugin)
end

function F.project_cd()
  F.lazy_load 'vim-projectroot'
  vim.cmd [[
    try
      if &ft != 'help'
        ProjectRootCD
      endif
    catch
    endtry
  ]]
end

function F.get_bnr_file(bnr)
  return F.rep(vim.api.nvim_buf_get_name(bnr))
end

function F.get_cur_file()
  return F.get_bnr_file(0)
end

function F.get_tail(file)
  if not file then
    file = F.get_cur_file()
  end
  return vim.fn.fnamemodify(file, ':t')
end

function F.put_uniq(arr, item)
  if not F.in_arr(item, arr) then
    F.put(arr, item)
  end
end

function F.merge_tables(...)
  local result = {}
  for _, t in ipairs { ..., } do
    for _, v in ipairs(t) do
      F.put_uniq(result, v)
    end
  end
  return result
end

function F.get_all_win_buf_nrs()
  local buf_nrs = {}
  for i = 1, vim.fn.tabpagenr '$' do
    local bufs = vim.fn.tabpagebuflist(i)
    if #bufs > 0 then
      buf_nrs = F.merge_tables(buf_nrs, bufs)
    end
  end
  return buf_nrs
end

return F
