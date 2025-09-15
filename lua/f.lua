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

function F.in_str(item, str)
  return string.match(str, item)
end

function F.is_term(file)
  return F.in_str('term://', file) or F.in_str('term:\\\\', file)
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

function F.lower(content)
  return vim.fn.tolower(content)
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

function F.cmd(...)
  local cmd = string.format(...)
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

function F.format(...)
  return string.format(...)
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

function F.getlua(luafile)
  local loaded = string.match(F.rep(luafile), '.+lua\\(.+)%.lua')
  if not loaded then
    return nil
  end
  loaded = string.gsub(loaded, '\\', '.')
  return loaded
end


function F.getluapy(luafile)
  local parts = {}
  for part in string.gmatch(luafile, "[^\\]+") do
    table.insert(parts, part)
  end
  local last_lua_index = nil
  for i = #parts, 1, -1 do
    if parts[i] == "lua" then
      if i < #parts then
        last_lua_index = i
        break
      end
    end
  end
  if last_lua_index then
    parts[last_lua_index] = "plugin"
  end
  return table.concat(parts, "\\"), last_lua_index
end

function F.getpylua(pyfile)
  local parts = {}
  for part in string.gmatch(pyfile, "[^\\]+") do
    table.insert(parts, part)
  end
  local last_lua_index = nil
  for i = #parts, 1, -1 do
    if parts[i] == "plugin" then
      if i < #parts then
        last_lua_index = i
        break
      end
    end
  end
  if last_lua_index then
    parts[last_lua_index] = "lua"
  end
  return table.concat(parts, "\\"), last_lua_index
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

function F.get_proj(file)
  local proj = ''
  F.lazy_load 'vim-projectroot'
  if file and F.in_str('diffview://', file) then
    file = string.gsub(file, '^diffview://', '')
  end
  if file then
    _, proj = pcall(vim.fn['ProjectRootGet'], file)
  else
    _, proj = pcall(vim.fn['ProjectRootGet'])
  end
  return F.rep(proj)
end

function F.new_file(file)
  return require 'plenary.path':new(F.rep(file))
end

function F.get_parent(file)
  if not file then
    file = F.get_cur_file()
  end
  return F.new_file(file):parent().filename
end

function F.is_file_exists(file)
  file = vim.fn.trim(file)
  if #file == 0 then
    return nil
  end
  local fp = F.new_file(file)
  if fp:exists() then
    return fp
  end
  return nil
end

function F.is_file(file)
  local fp = F.is_file_exists(F.rep(file))
  if fp and fp:is_file() then
    return 1
  end
  return nil
end

function F.is_dir(file)
  local fp = F.is_file_exists(F.rep(file))
  if fp and fp:is_dir() then
    return 1
  end
  return nil
end

function F.jump_or_split(file, no_split)
  if not file then
    return
  end
  if type(file) == 'number' then
    if F.is_bnr_valid(file) then
      file = vim.g.file
    else
      return
    end
  end
  file = F.rep(file)
  if F.is_dir(file) then
    F.lazy_load 'nvim-tree.lua'
    vim.cmd 'wincmd s'
    F.cmd('e %s', file)
    return
  end
  local file_proj = F.get_proj(file)
  local jumped = nil
  for winnr = vim.fn.winnr '$', 1, -1 do
    local bufnr = vim.fn.winbufnr(winnr)
    local fname = F.rep(F.get_bnr_file(bufnr))
    if F.lower(file) == F.lower(fname) and (F.is_file_exists(fname) or F.is_term(fname)) then
      vim.fn.win_gotoid(vim.fn.win_getid(winnr))
      jumped = 1
      break
    end
  end
  if not jumped then
    for winnr = vim.fn.winnr '$', 1, -1 do
      local bufnr = vim.fn.winbufnr(winnr)
      local fname = F.rep(F.get_bnr_file(bufnr))
      if F.is_file_exists(fname) then
        local proj = F.get_proj(fname)
        if not F.is(file_proj) or F.is(proj) and F.lower(file_proj) == F.lower(proj) then
          vim.fn.win_gotoid(vim.fn.win_getid(winnr))
          jumped = 1
          break
        end
      end
    end
  end
  if not jumped and not no_split then
    if F.is(F.get_cur_file()) or vim.bo[vim.fn.bufnr()].modified == true then
      vim.cmd 'wincmd s'
    end
  end
  F.cmd('e %s', file)
end

function F.edit(file)
  if not file then
    return
  end
  F.cmd('e %s', file)
end

function F.get_ft_bnr(ft)
  if not ft then
    return nil
  end
  for _, buf in ipairs(F.get_win_buf_nrs()) do
    if ft == vim.bo[buf].filetype then
      return buf
    end
  end
end

function F.lazy_map(tbls)
  for _, tbl in ipairs(tbls) do
    local opt = {}
    for k, v in pairs(tbl) do
      if type(k) == 'string' and k ~= 'mode' then
        opt[k] = v
      end
    end
    local lhs = tbl[1]
    if type(lhs) == 'table' then
      for _, l in ipairs(lhs) do
        vim.keymap.set(tbl['mode'], l, tbl[2], opt)
      end
    else
      vim.keymap.set(tbl['mode'], lhs, tbl[2], opt)
    end
  end
end

function F.findall(patt, str)
  vim.g.patt = patt
  vim.g.str = str
  vim.g.res = {}
  vim.cmd [[
    python << EOF
import re
import vim
try:
  import luadata
except:
  import os
  os.system('pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com luadata')
  import luadata
patt = vim.eval('g:patt')
string = vim.eval('g:str')
res = re.findall(patt, string)
if res:
  new_res = eval(str(res).replace('(', '[').replace(')', ']'))
  new_res = luadata.serialize(new_res, encoding='utf-8', indent=' ', indent_level=0)
  vim.command(f"""lua vim.g.res = {new_res}""")
EOF
  ]]
  return vim.g.res
end

function F.just_get_git_remote_url(proj)
  local remote = ''
  if proj then
    remote = vim.fn.system(string.format('cd %s && git remote -v', proj))
  else
    remote = vim.fn.system 'git remote -v'
  end
  local res = F.findall([[\s([^\s]*git.*\.com[^\s]+)\s]], remote)
  if #res >= 1 then
    return res[1]
  end
  return ''
end

function F.copy_multiple_filenames()
  vim.fn.setreg('w', vim.loop.cwd())
  vim.fn.setreg('a', F.get_cur_file())
  vim.fn.setreg('b', vim.fn.bufname())
  vim.fn.setreg('t', vim.fn.fnamemodify(vim.fn.bufname(), ':t'))
  vim.fn.setreg('e', vim.fn.expand '<cword>')
  vim.fn.setreg('r', vim.fn.expand '<cWORD>')
  vim.fn.setreg('i', vim.fn.trim(vim.fn.getline '.'))
  vim.fn.setreg('u', F.just_get_git_remote_url())
  vim.fn.setreg('d', vim.fn.strftime '%Y%m%d')
end

function F.telescope_cmd_dir(cmd, dir)
  F.lazy_load 'telescope'
  if dir then
    F.cmd('Telescope %s cwd=%s', cmd, dir)
    return
  end
  F.cmd('Telescope %s', cmd)
end

function F.run_and_exit(...)
  local cmd = string.format(...)
  F.cmd([[silent !start cmd /c "%s"]], cmd)
end

function F.run_and_silent(...)
  local cmd = string.format(...)
  F.cmd([[silent !start /b /min cmd /c "%s"]], cmd)
end

function F.run_and_pause(...)
  local cmd = string.format(...)
  F.cmd([[silent !start cmd /c "%s & pause"]], cmd)
end

function F.prev_hunk()
  if vim.wo.diff then
    vim.cmd [[call feedkeys("[c")]]
    return
  end
  require 'gitsigns'.prev_hunk()
end

function F.next_hunk()
  if vim.wo.diff then
    vim.cmd [[call feedkeys("]c")]]
    return
  end
  require 'gitsigns'.next_hunk()
end

function F.read_lines_from_file(file)
  if F.is_file_exists(file) then
    return vim.fn.readfile(file)
  end
  return {}
end

function F.write_lines_to_file(lines, file)
  vim.fn.writefile(lines, file)
end

function F.to_table(any)
  if type(any) ~= 'table' then
    return { any, }
  end
  return any
end

function F.delete_files(files)
  if not files then
    local file = F.get_cur_file()
    if F.is_file(file) then
      files = { file, }
    end
  end
  if not files then
    return
  end
  F.lazy_load 'vim-bbye'
  for _, file in ipairs(files) do
    local bnr = vim.fn.bufnr(file)
    if F.is_file_exists(file) then
      if 0 ~= vim.fn.confirm(F.format('Delete %s?', file)) then
        F.cmd('Bwipeout! %d', bnr)
        F.run_and_silent('del /f /s %s', file)
      end
    end
  end
end

return F
