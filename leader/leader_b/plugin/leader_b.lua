local B = require 'leader_b'

require 'which-key'.register {
  ['<leader>b'] = { name = 'leader_b', },
  ['<leader>bw'] = { function() B.swap_file() end, 'swap_file', mode = { 'n', 'v', }, },
}
