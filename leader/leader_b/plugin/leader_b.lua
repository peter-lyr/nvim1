local B = require 'leader_b'

require 'which-key'.register {
  ['<leader>b'] = { name = 'leader_b', },
  ['<leader>bw'] = { function() B.swap_file() end, 'swap_file', mode = { 'n', 'v', }, },
  ['<leader>bn'] = { function() require 'f'.notifications_buffer() end, 'notifications_buffer', mode = { 'n', 'v', }, },
  ['<leader>bm'] = { function() require 'f'.message_buffer() end, 'message_buffer', mode = { 'n', 'v', }, },
  ['<leader>b<leader>m'] = { function() vim.cmd 'mes clear' end, 'mes clear', mode = { 'n', 'v', }, },
  ['<leader>b<leader>n'] = { function() vim.cmd 'NotificationsClear' end, 'NotificationsClear', mode = { 'n', 'v', }, },
}
