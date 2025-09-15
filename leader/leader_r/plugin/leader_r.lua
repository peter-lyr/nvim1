local R = require 'leader_r'

require 'which-key'.register {
  ['<leader>r'] = { name = 'leader_r', },
  ['<leader>r.'] = { function() R.run_cur_file() end, 'run_and_pause', mode = { 'n', 'v', }, },
  ['<leader>rf'] = { function() require 'spectre'.open_file_search { select_word = true, } end, 'Find <cword> & Replace in current buffer', mode = { 'n', 'v', }, silent = true, },
  ['<leader>rw'] = { function() require 'spectre'.open_visual { select_word = true, } end, 'Find <cword> & Replace in current project', mode = { 'n', 'v', }, silent = true, },
}
