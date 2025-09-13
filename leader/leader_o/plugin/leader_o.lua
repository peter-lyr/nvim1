local O = require 'leader_o'

require 'which-key'.register {
  ['<leader>o'] = { name = 'leader_o', },
  ['<leader>ow'] = { function() O.open_work_md() end, 'open: work.md', mode = { 'n', 'v', }, silent = true, },
}
