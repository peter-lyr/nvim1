return {

  {
    name = 'bufreadpost',
    dir = '',
    event = 'BufReadPost',
    config = function()
      local desc = 'BufReadPost.get_mark'
      vim.api.nvim_create_autocmd('BufReadPost', {
        group = vim.api.nvim_create_augroup(desc, {}),
        desc = desc,
        callback = function()
          local mark = vim.api.nvim_buf_get_mark(0, '"')
          local lcount = vim.api.nvim_buf_line_count(0)
          if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end,
      })
      desc = 'BufReadPost.tabs'
      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup(desc, {}),
        desc = desc,
        callback = function(ev)
          local ext = string.match(vim.fn.bufname(ev.buf), '%.([^.]+)$')
          if ext == 'xxd' then
            vim.cmd 'setlocal ft=xxd'
          end
          require 'f'.project_cd()
        end,
      })
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('close_with_q', { clear = true, }),
        pattern = {
          'help',
          'lspinfo',
          'notify',
          'qf',
          'query',
          'spectre_panel',
          'startuptime',
          'tsplayground',
          'neotest-output',
          'checkhealth',
          'TelescopePrompt',
          'myft-empty-exit',
          'DiffviewFileHistory',
          'myft',
        },
        callback = function(ev)
          vim.bo[ev.buf].buflisted = false
          vim.keymap.set('n', 'q', function()
            if vim.api.nvim_get_option_value('filetype', { buf = ev.buf, }) ~= 'myft-empty-exit' then
              vim.cmd 'close!'
              return
            end
            if #require 'f'.get_cur_file() == 0 and vim.api.nvim_get_option_value('modified', { buf = ev.buf, }) == false then
              vim.cmd 'close!'
            end
          end, { buffer = ev.buf, nowait = true, silent = true, })
        end,
      })
    end,
  },

  {
    name = 'textyankpost',
    dir = '',
    event = 'TextYankPost',
    config = function()
      local desc = 'textyankpost.highlight'
      vim.api.nvim_create_autocmd('TextYankPost', {
        group = vim.api.nvim_create_augroup(desc, {}),
        desc = desc,
        callback = function()
          vim.highlight.on_yank()
        end,
      })
    end,
  },

  {
    name = 'termopen',
    dir = '',
    event = 'TermOpen',
    config = function()
      vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'escape', })
    end,
  },

  {
    name = 'textchanged',
    dir = '',
    event = { 'ModeChanged', 'TextChanged', 'TextChangedI', },
    config = function()
      vim.keymap.set('v', '<tab>h', '"hy', { desc = '"hy', })
      vim.keymap.set('v', '<tab>j', '"jy', { desc = '"jy', })
      vim.keymap.set('v', '<tab>k', '"ky', { desc = '"ky', })
      vim.keymap.set('v', '<tab>l', '"ly', { desc = '"ly', })
      vim.keymap.set('v', '<tab>g', '"+y', { desc = '"+y', })
      vim.keymap.set('v', '<tab>y', '"+y', { desc = '"+y', })
      vim.keymap.set({ 'i', 'c', }, '<c-r>;', '<c-r>:', { desc = '<c-r>:', })
      vim.keymap.set({ 'i', 'c', }, "<c-r>'", '<c-r>"', { desc = '<c-r>"', })
      vim.keymap.set({ 'i', 'c', }, '<c-v>', '<c-r>+', { desc = '<c-r>+', })
      vim.keymap.set({ 'i', 'c', }, '<c-r><leader>', '<c-r>+', { desc = '<c-r>+', })
      vim.keymap.set({ 'c', }, '<c-h>', '<left>', { desc = '<left>', })
      vim.keymap.set({ 'c', }, '<c-l>', '<right>', { desc = '<right>', })
      vim.keymap.set({ 'c', }, '<c-a>', '<home>', { desc = '<home>', })
      vim.keymap.set({ 'c', }, '<c-e>', '<end>', { desc = '<end>', })
      vim.keymap.set('t', "<c-'>", '<c-\\><c-n>pi', { desc = '<c-r>"', })
      vim.keymap.set('t', '<c-v>', '<c-\\><c-n>"+pi', { desc = '<c-r>+', })
      vim.keymap.set('t', '<c-a>', '<home>', { desc = '<home>', })
      vim.keymap.set('t', '<c-e>', '<end>', { desc = '<end>', })
      vim.keymap.set('t', '<c-k>', '<up>', { desc = '<up>', })
      vim.keymap.set('t', '<c-j>', '<down>', { desc = '<down>', })
      vim.keymap.set('t', '<c-h>', '<left>', { desc = '<left>', })
      vim.keymap.set('t', '<c-l>', '<right>', { desc = '<right>', })
      vim.keymap.set('t', '<c-;>', '<c-left>', { desc = '<c-left>', })
      vim.keymap.set('t', "<c-'>", '<c-right>', { desc = '<c-right>', })
      vim.keymap.set('t', '<c-u>', '<c-h>', { desc = '<c-h>', })
      vim.keymap.set('n', 'y<tab>', function() require 'f'.copy_multiple_filenames() end, { desc = 'copy_multiple_filenames', })
      vim.keymap.set('n', 'y<leader>', '"+y', { desc = '"+y', })
    end,
  },

  {
    name = 'uienter',
    dir = '',
    event = 'UIEnter',
    config = function()
      vim.fn['GuiWindowFrameless'](1)
      vim.cmd 'GuiWindowOpacity 0.9'
      vim.fn['GuiWindowMaximized'](0)
      vim.fn['GuiWindowMaximized'](1)
      vim.fn['GuiWindowMaximized'](0)
    end,
  },

  {
    name = 'vimleavepre',
    dir = '',
    event = 'VimLeavePre',
    config = function()
      vim.fn['GuiWindowFullScreen'](0)
      vim.fn['GuiWindowMaximized'](0)
      vim.fn['GuiWindowFrameless'](0)
    end,
  },

}
