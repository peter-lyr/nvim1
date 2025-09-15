return {

  'nvim-lua/plenary.nvim',

  -- whichkey
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    tag = 'v2.1.0',
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    keys = {
      { '<a-w>', '<cmd>WhichKey "" n<cr>', mode = { 'n', }, desc = 'WhichKey n', },
      { '<a-w>', '<cmd>WhichKey "" v<cr>', mode = { 'v', }, desc = 'WhichKey v', },
      { '<a-w>', '<cmd>WhichKey "" i<cr>', mode = { 'i', }, desc = 'WhichKey i', },
      { '<a-w>', '<cmd>WhichKey "" c<cr>', mode = { 'c', }, desc = 'WhichKey c', },
      { '<a-w>', '<cmd>WhichKey "" t<cr>', mode = { 't', }, desc = 'WhichKey t', },
    },
    config = function()
      require 'which-key'.setup {}
    end,
  },

  {
    'peter-lyr/vim-projectroot',
    config = function()
      vim.g.rootmarkers = {
        '.cache', 'build', '.clang-format', '.clangd', 'CMakeLists.txt', 'compile_commands.json',
        '.svn', '.git',
        '.root',
      }
      require 'f'.aucmd({ 'BufEnter', 'BufWinEnter', 'WinEnter', }, 'AutoProjectRootCD', {
        callback = function()
          require 'f'.project_cd()
        end,
      })
    end,
  },

  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile', },
    keys = {
      { '<leader>k', function() require 'f'.prev_hunk() end, desc = 'prev_hunk', },
      { '<leader>j', function() require 'f'.next_hunk() end, desc = 'next_hunk', },
      { 'ag',        ':<C-U>Gitsigns select_hunk<CR>',       desc = 'git.signs: select_hunk', mode = { 'o', 'x', }, silent = true, },
      { 'ig',        ':<C-U>Gitsigns select_hunk<CR>',       desc = 'git.signs: select_hunk', mode = { 'o', 'x', }, silent = true, },
    },
    config = function()
      require 'gitsigns'.setup {
        signs               = {
          add = { text = '+', },
          change = { text = '~', },
          delete = { text = '_', },
          topdelete = { text = '‾', },
          changedelete = { text = '', },
          untracked = { text = '?', },
        },
        signs_staged_enable = true,
        signcolumn          = true,
        numhl               = true,
        attach_to_untracked = true,
      }
    end,
  },

}
