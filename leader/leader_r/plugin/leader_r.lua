local R = require 'leader_r'

require 'which-key'.register {
  ['<leader>r'] = { name = 'leader_r', },
  ['<leader>r.'] = { function() R.run_and_pause() end, 'run_and_pause', mode = { 'n', 'v', }, },
}
