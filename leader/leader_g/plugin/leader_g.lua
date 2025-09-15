local G = require 'leader_g'

require 'which-key'.register {
  ['<leader>g'] = { name = 'leader_g', },
  ['<leader>ga'] = { function() G.add_commit_push_edit_status() end, 'add_commit_push_edit_status', mode = { 'n', 'v', }, },
  ['<leader>g<leader>ay'] = { function() G.add_commit_push_yank() end, 'add_commit_push_yank', mode = { 'n', 'v', }, },
}
