local C = require 'leader_c'

require 'f'.lazy_load 'nerdcommenter'

require 'which-key'.register {
  ['<leader>c'] = { name = 'leader_c', },
  ['<leader>cp'] = { "}kvip:call nerdcommenter#Comment('x', 'toggle')<CR>", 'comment: paragraph', mode = { 'n', }, },
  ['<leader>co'] = { "}kvip:call nerdcommenter#Comment('x', 'invert')<CR>", 'comment: paragraph', mode = { 'n', }, },
}
