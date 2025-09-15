require 'which-key'.register {
  -- ['<leader>se'] = { function() require 'f'.telescope_extras() end, 'builtin', mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>s'] = { name = 'telescope', },
  ['<leader>s<leader>'] = { name = 'telescope.more', },
  ['<leader>s<leader><leader>'] = { name = 'telescope.more', },

  -- -- W L P
  -- ['<leader>s<leader>o'] = { function() require 'f'.telescope_sel(require 'f'.get_sub_dirs(W), 'file_browser') end, 'file_browser sel W', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader>i'] = { function() require 'f'.telescope_sel(require 'f'.get_sub_dirs(L), 'file_browser') end, 'file_browser sel L', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader>p'] = { function() require 'f'.telescope_sel(require 'f'.get_sub_dirs(P), 'file_browser') end, 'file_browser sel P', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader><leader>f'] = { name = 'telescope.more', },
  -- ['<leader>s<leader><leader>fo'] = { function() require 'f'.telescope('file_browser', W) end, 'file_browser in W', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader><leader>fi'] = { function() require 'f'.telescope('file_browser', L) end, 'file_browser in L', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader><leader>fp'] = { function() require 'f'.telescope('file_browser', P) end, 'file_browser in P', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader><leader>l'] = { name = 'telescope.more', },
  -- ['<leader>s<leader><leader>lo'] = { function() require 'f'.telescope('live_grep', W) end, 'live_grep in W', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader><leader>li'] = { function() require 'f'.telescope('live_grep', L) end, 'live_grep in L', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader><leader>lp'] = { function() require 'f'.telescope('live_grep', P) end, 'live_grep in P', mode = { 'n', 'v', }, },

  -- ['<leader>s<leader>d'] = { function() require 'f'.telescope_sel(require 'f'.get_sh_get_folder_path 'desktop', 'file_browser') end, 'file_browser sel Desktop', mode = { 'n', 'v', }, },

  -- reload
  -- ['<leader>sr'] = { function() require 'f'.source(StdConfig .. 'lua\\_telescope.lua') end, 'resource telescope', mode = { 'n', 'v', }, },

  -- builtin
  -- ['<leader>sz'] = { '<cmd>Telescope current_buffer_fuzzy_find<cr>', 'current_buffer_fuzzy_find', mode = { 'n', 'v', }, },
  ['<leader>sh'] = { '<cmd>Telescope help_tags<cr>', 'help_tags', mode = { 'n', 'v', }, },
  ['<leader>sa'] = { '<cmd>Telescope builtin<cr>', 'builtin', mode = { 'n', 'v', }, },

  -- file_browser
  -- ['<leader>sw'] = { function() require 'f'.cmd('Telescope file_browser cwd=%s', require 'f'.escape_space(require 'f'.get_parent())) end, 'file_browser cur', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader>w'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'file_browser') end, 'file_browser sel', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader>f'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'fd') end, 'fd_sel', mode = { 'n', 'v', }, },
  -- ['<leader>sj'] = { function() require 'f'.opened_proj_sel() end, 'opened_proj_sel', mode = { 'n', 'v', }, },
  ['<leader>sp'] = { '<cmd>Telescope project<cr>', 'project', mode = { 'n', 'v', }, },

  -- search string
  ['<leader>sl'] = { '<cmd>Telescope live_grep<cr>', 'live_grep', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader>l'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'live_grep') end, 'live_grep_sel', mode = { 'n', 'v', }, },
  ['<leader>ss'] = { '<cmd>Telescope grep_string<cr>', 'grep_string', mode = { 'n', 'v', }, },
  -- ['<leader>s<leader>s'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'grep_string') end, 'grep_string_sel', mode = { 'n', 'v', }, },

  -- git
  ['<leader>sg'] = { name = 'telescope.git', },
  ['<leader>sgc'] = { '<cmd>Telescope git_commits<cr>', 'git_commits', mode = { 'n', 'v', }, },
  -- ['<leader>sg<leader>c'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'git_commits') end, 'git_commits_sel', mode = { 'n', 'v', }, },
  ['<leader>sgs'] = { '<cmd>Telescope git_status<cr>', 'git_status', mode = { 'n', 'v', }, },
  -- ['<leader>sg<leader>s'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'git_status') end, 'git_status_sel', mode = { 'n', 'v', }, },
  ['<leader>sgh'] = { '<cmd>Telescope git_branches<cr>', 'git_branches', mode = { 'n', 'v', }, },
  -- ['<leader>sg<leader>h'] = { function() require 'f'.telescope_sel(require 'f'.get_file_more_dirs(), 'git_branches') end, 'git_branches_sel', mode = { 'n', 'v', }, },

  -- buffers
  -- ['<leader>sb'] = { function() require 'f'.cmd('Telescope buffers cwd=%s', require 'f'.get_cwd()) end, 'buffers cwd', mode = { 'n', 'v', }, },
  ['<leader>s<leader>b'] = { '<cmd>Telescope buffers<cr>', 'buffers all', mode = { 'n', 'v', }, },
  ['<leader>so'] = { function() vim.cmd('Telescope oldfiles') end, 'oldfiles', mode = { 'n', 'v', }, },
}
