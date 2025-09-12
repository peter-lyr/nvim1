vim.g.mapleader      = ' '
vim.g.maplocalleader = ','

Name                 = 'peter-lyr'
Email                = 'llydrp.ldp@gmail.com'

Home                 = vim.fn.expand '$HOME'
Dp1                  = Home .. '\\Dp1'

Dp1Temp              = Dp1 .. '\\temp'
TempTxt              = Dp1Temp .. '\\temp.txt'

TreeSitter           = Dp1 .. '\\TreeSitter'
Mason                = Dp1 .. '\\Mason'

StdConfig            = vim.fn.stdpath 'config' .. '\\'
StdData              = vim.fn.stdpath 'data' .. '\\'
LazyPath             = Dp1 .. '\\lazy\\lazy.nvim'
Nvim1                = Dp1 .. '\\lazy\\nvim1'
DataLazyPlugins      = Dp1 .. '\\lazy\\plugins'

math.huge            = 1073741824 -- 解决gitsigns的ig无用的问题

if not vim.loop.fs_stat(LazyPath) or vim.fn.filereadable(LazyPath .. '\\README.md') == 0 then
  vim.fn.system('rmdir /s /q "' .. LazyPath .. '"')
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    -- '--branch=stable', -- latest stable release
    -- '-b', 'v10.24.3',  -- v11的有的插件加载不了
    LazyPath,
  }
end

vim.opt.rtp:prepend(LazyPath)
vim.opt.rtp:prepend(Nvim1)

NvimQt = { string.sub(vim.env.VIMRUNTIME, 1, #vim.env.VIMRUNTIME - 12) .. 'nvim-qt\\runtime', }

require 'lazy'.setup {
  defaults = { lazy = true, },
  spec = {
    { import = 'plugins1', },
  },
  root = DataLazyPlugins,
  readme = { enabled = false, },
  lockfile = DataLazyPlugins .. '\\lazy-lock.json',
  performance = {
    rtp = {
      paths = NvimQt,
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
  checker = {
    enabled = false,
  },
  change_detection = {
    enabled = false,
  },
  ui = {
    icons = {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
    custom_keys = {
      ['<localleader>l'] = false,
      ['<localleader>t'] = false,
    },
  },
}
