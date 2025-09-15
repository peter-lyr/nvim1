local G = require 'leader_g'

require 'which-key'.register {
  ['<leader>g'] = { name = 'leader_g', },
  ['<leader>ga'] = { function() G.add_commit_push_edit() end, 'add_commit_push_edit', mode = { 'n', 'v', }, },
  ['<leader>g<leader>as'] = { function() G.add_commit_push_edit_status() end, 'add_commit_push_edit_status', mode = { 'n', 'v', }, },
  ['<leader>g<leader>ay'] = { function() G.add_commit_push_yank() end, 'add_commit_push_yank', mode = { 'n', 'v', }, },
  ['<leader>gr'] = { function() G.reset_hunk() end, 'reset_hunk', mode = { 'n', }, silent = true, },
  ['<leader>g<leader>r'] = { function() G.git_reset_buffer() end, 'git_reset_buffer', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>gr'] = { function() G.reset_hunk_v() end, 'reset_hunk', mode = { 'v', }, silent = true, },
}
