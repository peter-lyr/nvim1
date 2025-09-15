vim.g.mapleader      = ' '
vim.g.maplocalleader = ','

Name                 = 'peter-lyr'
Email                = 'llydrp.ldp@gmail.com'

Home                 = vim.fn.expand '$HOME'
Dp1                  = Home .. '\\Dp1'

Dp1Temp              = Dp1 .. '\\temp'
TempTxt              = Dp1Temp .. '\\temp.txt'
StdOutTxt            = Dp1Temp .. '\\stdout.txt'

TreeSitter           = Dp1 .. '\\TreeSitter'
Mason                = Dp1 .. '\\Mason'

LazyPath             = Dp1 .. '\\lazy\\lazy.nvim'
DataLazyPlugins      = Dp1 .. '\\lazy\\plugins'

Nvim1                = Dp1 .. '\\lazy\\nvim1'
Nvim1Leader          = Nvim1 .. '\\leader\\'

GitFakeRemoteDir     = Home .. '\\gfrd'

StdConfig            = vim.fn.stdpath 'config' .. '\\'
StdData              = vim.fn.stdpath 'data' .. '\\'

NvimQt               = string.sub(vim.env.VIMRUNTIME, 1, #vim.env.VIMRUNTIME - 12) .. 'nvim-qt\\runtime'

-- math.huge            = 1073741824 -- 解决gitsigns的ig无用的问题

vim.opt.number         = true
vim.opt.numberwidth    = 1
vim.opt.relativenumber = false
vim.opt.title          = true
vim.opt.winminheight   = 0
vim.opt.winminwidth    = 0
vim.opt.expandtab      = true
vim.opt.cindent        = true
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.smartcase      = true
vim.opt.smartindent    = true
vim.opt.cursorline     = true
vim.opt.cursorcolumn   = false
vim.opt.termguicolors  = true
vim.opt.splitright     = true
vim.opt.splitbelow     = true
vim.opt.mousemodel     = 'popup'
vim.opt.mousescroll    = 'ver:5,hor:0'
vim.opt.swapfile       = false
vim.opt.fileformats    = 'dos'
vim.opt.foldmethod     = 'indent'
vim.opt.foldlevel      = 99
vim.opt.titlestring    = 'Neovim-0114'
vim.opt.fileencodings  = 'utf-8,gbk,default,ucs-bom,latin'
vim.opt.shortmess:append { W = true, I = true, c = true, }
vim.opt.showmode       = true
vim.opt.undofile       = true
vim.opt.undolevels     = 10000
vim.opt.sidescrolloff  = 0
vim.opt.scrolloff      = 0
vim.opt.scrollback     = 100000
vim.opt.completeopt    = 'menu,menuone,noselect'
vim.opt.conceallevel   = 0
vim.opt.list           = true
vim.opt.updatetime     = 500
vim.opt.laststatus     = 3
vim.opt.equalalways    = false
vim.opt.linebreak      = true
-- vim.opt.sessionoptions = 'buffers,sesdir,folds,help,localoptions,winpos,winsize,terminal'
-- vim.opt.sessionoptions = 'folds,help,localoptions,winpos,winsize'
-- vim.opt.sessionoptions = 'blank,buffers,folds,globals,help,localoptions,options,resize,sesdir,tabpages,terminal,winpos,winsize'
vim.opt.sessionoptions = ''
vim.opt.shada          = [[!,'1000,<500,s10000,h,rA:,rB:]]
vim.opt.conceallevel   = 0
vim.opt.cmdheight      = 1

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

require 'lazy'.setup {
  defaults = { lazy = true, },
  spec = {
    { import = 'plugins', },
    { import = 'leaders', },
    { import = 'telescope', },
    { import = 'treesitter', },
  },
  root = DataLazyPlugins,
  readme = { enabled = false, },
  lockfile = DataLazyPlugins .. '\\lazy-lock.json',
  performance = {
    rtp = {
      paths = {
        NvimQt,
        Nvim1,
      },
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
