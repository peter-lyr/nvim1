local G = require("leader_g")

require("which-key").register({
	["<leader>g"] = { name = "leader_g" },
	["<leader>ga"] = {
		function()
			G.add_commit_push_edit()
		end,
		"add_commit_push_edit",
		mode = { "n", "v" },
	},
	["<leader>g<leader>as"] = {
		function()
			G.add_commit_push_edit_status()
		end,
		"add_commit_push_edit_status",
		mode = { "n", "v" },
	},
	["<leader>g<leader>ay"] = {
		function()
			G.add_commit_push_yank()
		end,
		"add_commit_push_yank",
		mode = { "n", "v" },
	},
	["<leader>g<leader>ai"] = {
		function()
			G.add_commit_push_cur_line()
		end,
		"add_commit_push_cur_line",
		mode = { "n", "v" },
	},
	["<leader>g<leader>ab"] = {
		function()
			G.add_commit_push_bufname()
		end,
		"add_commit_push_bufname",
		mode = { "n", "v" },
	},
	["<leader>gr"] = {
		function()
			G.reset_hunk()
		end,
		"reset_hunk",
		mode = { "n" },
		silent = true,
	},
	["<leader>g<leader>r"] = {
		function()
			G.git_reset_buffer()
		end,
		"git_reset_buffer",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>gp"] = {
		function()
			G.pull()
		end,
		"pull",
		mode = { "n", "v" },
	},
	["<leader>gl"] = {
		function()
			G.log()
		end,
		"log",
		mode = { "n", "v" },
	},
})

require("which-key").register({
	["<leader>gr"] = {
		function()
			G.reset_hunk_v()
		end,
		"reset_hunk",
		mode = { "v" },
		silent = true,
	},
})
