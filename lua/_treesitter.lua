return {

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		ft = {
			"c",
			"cpp",
			"python",
			"lua",
			"markdown",
		},
		dependencies = {
			"andymass/vim-matchup",
			"nvim-treesitter/nvim-treesitter-context",
			"hiphish/rainbow-delimiters.nvim",
		},
		config = function()
			vim.opt.runtimepath:append(TreeSitter)
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"bash",
					"c",
					"diff",
					"html",
					"lua",
					"luadoc",
					"markdown",
					"markdown_inline",
					"query",
					"vim",
					"vimdoc",
					"python",
				},
				ignore_installed = {
					"org",
				},
				auto_install = true,
				parser_install_dir = TreeSitter,
				highlight = { enable = true },
				indent = { enable = true },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<localleader>f",
						node_incremental = "<localleader>f",
						scope_incremental = "<localleader>s",
						node_decremental = "<localleader>d",
					},
				},
			})
			require("rainbow-delimiters.setup").setup({})
			require("treesitter-context").setup({
				zindex = 1,
				mode = "topline",
				on_attach = function()
					local max_filesize = 1000 * 1024
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(0))
					if ok and stats and stats.size > max_filesize then
						return false
					end
					return true
				end,
				max_lines = 4,
				enable = true,
				multiwindow = false,
				min_window_height = 0,
				line_numbers = true,
				multiline_threshold = 20,
				trim_scope = "outer",
				separator = nil,
			})
			require("f").lazy_map({
				{
					"[e",
					function()
						require("treesitter-context").go_to_context(vim.v.count1)
					end,
					mode = { "n", "v" },
					silent = true,
					desc = "nvim.treesitter: go_to_context",
				},
			})
			vim.g.matchup_treesitter_stopline = 500
			vim.g.matchup_matchparen_offscreen = {}
			require("match-up").setup({
				treesitter = {
					stopline = 500,
				},
			})
		end,
	},
}
