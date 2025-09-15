local D = require 'leader_d'

require 'which-key'.register {
  ['<leader>d'] = { name = 'leader_d', },
  ['<leader>df'] = { function() D.delete_cur_file() end, 'delete_cur_file', mode = { 'n', 'v', }, },
  ['<leader>db'] = { function() D.delete_cur_buffer() end, 'delete_cur_buffer', mode = { 'n', 'v', }, },
}
