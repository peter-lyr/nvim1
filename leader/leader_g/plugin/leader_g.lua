local G = require 'leader_g'

require 'which-key'.register {
  ['<leader>g'] = { name = 'leader_g', },
  ['<leader>ga'] = { function() vim.cmd 'wincmd j' end, 'window go down', mode = { 'n', 'v', }, },
}
