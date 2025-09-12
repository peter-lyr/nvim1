return {

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

  -- leader_w
  {
    name = 'leader_w',
    dir = Nvim1Leader .. 'leader_w',
    keys = {
      { '<leader>w', desc = 'window', },
    },
  },

  -- leader_x
  {
    name = 'leader_x',
    dir = Nvim1Leader .. 'leader_x',
    keys = {
      { '<leader>x', desc = 'window.delete', },
    },
  },

}
