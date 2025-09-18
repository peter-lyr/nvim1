return {

	"nvim-lua/plenary.nvim",
	{
		"jghauser/mkdir.nvim",
		event = "BufNewFile",
	},
	"moll/vim-bbye",
	{
		"NMAC427/guess-indent.nvim",
		event = { "BufReadPre" },
		config = function()
			require("guess-indent").setup({})
		end,
	},
	"google/vim-searchindex",

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		tag = "v2.1.0",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		keys = {
			{ "<a-w>", '<cmd>WhichKey "" n<cr>', mode = { "n" }, desc = "WhichKey n" },
			{ "<a-w>", '<cmd>WhichKey "" v<cr>', mode = { "v" }, desc = "WhichKey v" },
			{ "<a-w>", '<cmd>WhichKey "" i<cr>', mode = { "i" }, desc = "WhichKey i" },
			{ "<a-w>", '<cmd>WhichKey "" c<cr>', mode = { "c" }, desc = "WhichKey c" },
			{ "<a-w>", '<cmd>WhichKey "" t<cr>', mode = { "t" }, desc = "WhichKey t" },
		},
		config = function()
			require("which-key").setup({})
		end,
	},

	{
		"peter-lyr/vim-projectroot",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.g.rootmarkers = {
				".cache",
				"build",
				".clang-format",
				".clangd",
				"CMakeLists.txt",
				"compile_commands.json",
				".svn",
				".git",
				".root",
			}
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
				callback = function()
					vim.cmd([[
            try
              if &ft != 'help'
                ProjectRootCD
              endif
            catch
            endtry
          ]])
				end,
				group = vim.api.nvim_create_augroup("AutoProjectRootCD", {}),
				desc = "AutoProjectRootCD",
			})
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{
				"<leader>k",
				function()
					if vim.wo.diff then
						vim.cmd([[call feedkeys("[c")]])
						return
					end
					require("gitsigns").prev_hunk()
				end,
				desc = "prev_hunk",
			},
			{
				"<leader>j",
				function()
					if vim.wo.diff then
						vim.cmd([[call feedkeys("]c")]])
						return
					end
					require("gitsigns").next_hunk()
				end,
				desc = "next_hunk",
			},
			{
				"ag",
				":<C-U>Gitsigns select_hunk<CR>",
				desc = "git.signs: select_hunk",
				mode = { "o", "x" },
				silent = true,
			},
			{
				"ig",
				":<C-U>Gitsigns select_hunk<CR>",
				desc = "git.signs: select_hunk",
				mode = { "o", "x" },
				silent = true,
			},
		},
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "" },
					untracked = { text = "?" },
				},
				signs_staged_enable = true,
				signcolumn = true,
				numhl = true,
				attach_to_untracked = true,
			})
		end,
	},

	{
		"Pocco81/auto-save.nvim",
		event = { "InsertLeave", "TextChanged", "CursorHoldI" },
		config = function()
			require("auto-save").setup({
				execution_message = {
					message = function()
						return ""
					end,
				},
				trigger_events = { "TextChanged" },
			})
			require("auto-save").on()
		end,
	},

	{
		"catppuccin/nvim",
		name = "catppuccin",
		event = { "VeryLazy" },
		config = function()
			vim.fn.timer_start(50, function()
				require("catppuccin").setup({
					dim_inactive = {
						enabled = true,
						shade = "dark",
						percentage = 0,
					},
					no_italic = true,
					styles = {
						comments = {},
						conditionals = {},
					},
					integrations = {
						notify = true,
					},
				})
				vim.cmd.colorscheme("catppuccin-frappe")
			end)
		end,
	},

	{
		"rcarriga/nvim-notify",
		keys = {
			{
				"<bs>",
				function()
					require("notify").dismiss()
				end,
				mode = { "n", "v" },
				desc = "notify dismiss",
			},
			{
				"<c-bs>",
				function()
					require("notify").dismiss()
				end,
				mode = { "n", "v" },
				desc = "notify dismiss",
			},
		},
		dependencies = {
			{
				"stevearc/dressing.nvim",
				config = function()
					require("dressing").setup({
						input = {
							title_pos = "center",
							relative = "editor",
							prefer_width = 80,
							max_width = { 140, 0.9 },
							min_width = { 40, 0.2 },
						},
					})
				end,
			},
		},
		config = function()
			vim.notify = require("notify")
			require("notify").setup({
				max_width = 100,
				top_down = false,
				timeout = 8000,
				fps = 8,
				on_open = function(win)
					-- local buf = vim.api.nvim_win_get_buf(win)
					-- require 'f'.printf("buf:%s", buf)
					-- vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
				end,
			})
		end,
	},

	{
		"windwp/nvim-autopairs",
		event = { "InsertEnter", "CursorMoved" },
		dependencies = {
			"tpope/vim-surround",
		},
		config = function()
			local autopairs = require("nvim-autopairs")
			autopairs.setup({})
		end,
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "CursorMoved", "CursorMovedI" },
		dependencies = {
			"echasnovski/mini.indentscope",
		},
		config = function()
			-- indentscope
			require("mini.indentscope").setup({
				symbol = "│",
				options = { try_as_border = true },
			})
			-- indentblank
			require("ibl").setup({
				indent = {
					char = "│",
				},
				exclude = {
					filetypes = {
						--- my
						"qf",
						"mason",
						"notify",
						"startuptime",
						"NvimTree",
						"fugitive",
						"lazy",
						---
						"lspinfo",
						"packer",
						"checkhealth",
						"help",
						"man",
						"gitcommit",
						"TelescopePrompt",
						"TelescopeResults",
						"",
					},
				},
			})
		end,
	},

	{
		"preservim/nerdcommenter",
		dependencies = {
			"numToStr/Comment.nvim",
		},
		config = function()
			vim.g.NERDSpaceDelims = 1
			vim.g.NERDDefaultAlign = "left"
			vim.g.NERDCommentEmptyLines = 1
			vim.g.NERDTrimTrailingWhitespace = 1
			vim.g.NERDToggleCheckAllLines = 1
			vim.g.NERDCustomDelimiters = {
				dosbatch = {
					left = "REM",
					right = "",
				},
				python = {
					left = "#",
					right = "",
				},
				markdown = {
					left = "<!--",
					right = "-->",
					leftAlt = "[",
					rightAlt = "]: #",
				},
				c = {
					left = "//",
					right = "",
					leftAlt = "/*",
					rightAlt = "*/",
				},
				lisp = {
					left = ";;",
					right = "",
				},
				conf = {
					left = "//",
					right = "",
					leftAlt = "#",
					rightAlt = "",
				},
			}
			require("Comment").setup({})
		end,
	},

	{
		"phaazon/hop.nvim",
		keys = {
			{ "s", ":HopChar1<cr>", mode = { "n" }, silent = true, desc = "HopChar1" },
			-- { 't', ':HopChar2<cr>', mode = { 'n', }, silent = true, desc = 'HopChar2', },
		},
		config = function()
			require("hop").setup({
				keys = "asdghklqwertyuiopzxcvbnmfj",
			})
		end,
	},

	{
		"natecraddock/sessions.nvim",
		event = { "VeryLazy" },
		cmd = { "SessionsSave", "SessionsLoad", "SessionsStop" },
		config = function()
			require("sessions").setup({
				events = { "VimLeavePre" },
				session_filepath = Dp1Temp .. "\\sessions.vim",
				absolute = nil,
			})
		end,
	},

	{
		"nvim-pack/nvim-spectre",
		config = function()
			require("spectre").setup({
				replace_engine = {
					["sed"] = {
						cmd = Nvim1 .. "\\lua\\sed.exe",
						args = {
							"-i",
							"-E",
						},
						options = {
							["ignore-case"] = {
								value = "--ignore-case",
								icon = "[I]",
								desc = "ignore case",
							},
						},
					},
					["oxi"] = {
						cmd = "oxi",
						args = {},
						options = {
							["ignore-case"] = {
								value = "i",
								icon = "[I]",
								desc = "ignore case",
							},
						},
					},
				},
			})
		end,
	},
}
