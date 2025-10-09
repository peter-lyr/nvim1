local G = require("leader_g")

require("which-key").register({
	["<leader>g"] = { name = "leader_g" },
	["<leader>g<leader>as"] = {
		function()
			G.add_commit_push_edit()
		end,
		"add_commit_push_edit",
		mode = { "n", "v" },
	},
	["<leader>ga"] = {
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
	["<leader>g<leader>aw"] = {
		function()
			G.add_commit_push_cword()
		end,
		"add_commit_push_cword",
		mode = { "n", "v" },
	},
	["<leader>g<leader>a<leader>w"] = {
		function()
			G.add_commit_push_cWORD()
		end,
		"add_commit_push_cWORD",
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
	["<leader>gx"] = { name = "git reset" },
	["<leader>gxh"] = {
		function()
			G.git_reset_hard()
		end,
		"git_reset_hard",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>gxc"] = {
		function()
			G.git_reset_clean_fd()
		end,
		"git_reset_clean_fd",
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
	["<leader>gP"] = {
		function()
			G.push()
		end,
		"push",
		mode = { "n", "v" },
	},
	["<leader>g<leader>l"] = {
		function()
			G.log()
		end,
		"log",
		mode = { "n", "v" },
	},
	["<leader>gl"] = {
		function()
			G.log_oneline()
		end,
		"log",
		mode = { "n", "v" },
	},
	["<leader>gu"] = {
		function()
			G.status()
		end,
		"status",
		mode = { "n", "v" },
	},
	["<leader>gv"] = { name = "move" },
	["<leader>gvs"] = {
		function()
			G.diffview_stash()
		end,
		"diffview_stash",
		mode = { "n", "v" },
	},
	["<leader>gvo"] = {
		function()
			G.diffview_open()
		end,
		"diffview_open",
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
