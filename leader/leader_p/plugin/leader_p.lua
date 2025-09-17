local P = require 'leader_p'

require 'which-key'.register {
  ['<leader>p'] = { name = 'leader_p', },
  ['<leader>pg'] = { '"+p', '"+p', mode = { 'n', 'v', }, },
  ['<leader>p;'] = { '":p', '":p', mode = { 'n', 'v', }, },
  ['<leader>p/'] = { '"/p', '"/p', mode = { 'n', 'v', }, },
}
