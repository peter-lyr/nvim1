return {

  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-telescope/telescope-file-browser.nvim',
      'nvim-telescope/telescope-project.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
      'paopaol/telescope-git-diffs.nvim',
      'sindrets/diffview.nvim',
    },
    config = function()
      local Path = require 'plenary.path'
      local action_state = require 'telescope.actions.state'
      local actions = require 'telescope.actions'
      local fb_utils = require 'telescope._extensions.file_browser.utils'
      local os_sep = Path.path.sep
      local open = function(prompt_bufnr)
        local quiet = action_state.get_current_picker(prompt_bufnr).finder.quiet
        local selections = fb_utils.get_selected_files(prompt_bufnr, true)
        if vim.tbl_isempty(selections) then
          fb_utils.notify('actions.open', { msg = 'No selection to be opened!', level = 'INFO', quiet = quiet, })
          return
        end
        for _, selection in ipairs(selections) do
          local file = selection:absolute()
          if (require 'f'.is_file(file)) then
            require 'f'.run_and_silent(file)
          else
            require 'f'.run_and_silent('explorer ' .. file)
          end
        end
        actions.close(prompt_bufnr)
      end
      -- utility to get absolute path of target directory for create, copy, moving files/folders
      local get_target_dir = function(finder)
        local entry_path
        if finder.files == false then
          local entry = action_state.get_selected_entry()
          entry_path = entry and entry.value -- absolute path
        end
        return finder.files and finder.path or entry_path
      end
      local telescope_do = function(prompt_bufnr, cmd)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local finder = current_picker.finder
        local base_dir = get_target_dir(finder) .. os_sep
        local selections = fb_utils.get_selected_files(prompt_bufnr, true)
        if not vim.tbl_isempty(selections) then
          for _, selection in ipairs(selections) do
            local file = selection:absolute()
            actions.close(prompt_bufnr)
            if (require 'f'.is_file(file)) then
              require 'f'.telescope_cmd_dir(cmd, require 'f'.get_parent(file))
            else
              require 'f'.telescope_cmd_dir(cmd, file)
            end
            return
          end
        else
          actions.close(prompt_bufnr)
          require 'f'.telescope_cmd_dir(cmd, base_dir)
        end
      end
      local fd = function(prompt_bufnr)
        telescope_do(prompt_bufnr, 'fd')
      end
      local rg = function(prompt_bufnr)
        telescope_do(prompt_bufnr, 'live_grep')
      end
      require 'telescope'.setup {
        defaults = {
          mappings = {
            i = {
              ['<c-h>'] = require 'telescope.actions.layout'.toggle_preview,
              ['<c-j>'] = require 'telescope.actions'.move_selection_next,
              ['<c-k>'] = require 'telescope.actions'.move_selection_previous,
            },
            n = {
              ['<c-h>'] = require 'telescope.actions.layout'.toggle_preview,
            },
          },
          file_ignore_patterns = {
            'build/',
            '.cache/',
            '%.json',
            'CMakeLists.txt',
            '%.layout',
          },
        },
        extensions = {
          project = {
            base_dirs = {
              DataLazyPlugins,
              Dp1,
              GitFakeRemoteDir,
              LazyPath,
              L,
              P,
              W,
              vim.fn.expand '$HOME' .. '\\Dp1\\lazy\\nvim1',
              { Home,                              max_depth = 2, },
              { StdConfig,                         max_depth = 9, },
              { StdData .. 'lazy\\plugins', },
              { vim.fn.stdpath 'config' .. '\\..', max_depth = 2, },
            },
          },
          file_browser = {
            hijack_netrw = true,
            mappings = {
              ['i'] = {
                ['<C-o>'] = open,
                ['<C-;>'] = fd,
                ['<C-l>'] = rg,
              },
              ['n'] = {
                ['o'] = open,
                [';'] = fd,
                ['l'] = rg,
              },
            },
          },
        },
      }
      local function toggle_result_wrap()
        for winnr = 1, vim.fn.winnr '$' do
          local bufnr = vim.fn.winbufnr(winnr)
          local temp = vim.api.nvim_win_get_option(vim.fn.win_getid(winnr), 'wrap')
          local wrap = true
          if temp == true then
            wrap = false
          end
          if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'TelescopeResults' then
            vim.api.nvim_win_set_option(vim.fn.win_getid(winnr), 'wrap', wrap)
          end
        end
      end
      -- 对ui-select无效
      vim.api.nvim_create_autocmd({ 'User', }, {
        pattern = 'TelescopePreviewerLoaded',
        callback = function()
          vim.opt.number         = true
          vim.opt.relativenumber = true
          vim.opt.wrap           = true
          local bnr              = require 'f'.get_ft_bnr 'TelescopePrompt'
          if bnr then
            require 'f'.lazy_map {
              { '<c-bs>', toggle_result_wrap, mode = { 'n', }, silent = true, buffer = bnr, desc = 'telescope: toggle result wrap', },
              { '<c-bs>', toggle_result_wrap, mode = { 'i', }, silent = true, buffer = bnr, desc = 'telescope: toggle result wrap', },
            }
          end
        end,
      })
      vim.api.nvim_create_autocmd({ 'User', }, {
        pattern = 'TelescopeFindPre',
        callback = function()
          require 'f'.copy_multiple_filenames()
        end,
      })
      require 'diffview'.setup {
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                max_count = 16,
              },
              multi_file = {
                max_count = 16,
              },
            },
          },
        },
      }
      require 'telescope'.load_extension 'project'
      require 'telescope'.load_extension 'file_browser'
      require 'telescope'.load_extension 'ui-select'
      require 'telescope'.load_extension 'git_diffs'
    end,
  },
}
