local R = require("leader_r")

require("which-key").register({
	["<leader>r"] = { name = "leader_r" },
	["<leader>rp"] = {
		function()
			R.run_cur_file()
		end,
		"run_cur_file_console_pause",
		mode = { "n", "v" },
	},
	["<leader>rs"] = {
		function()
			R.run_cur_file_silent()
		end,
		"run_cur_file_silent",
		mode = { "n", "v" },
	},
	["<leader>re"] = {
		function()
			R.run_cur_file_exit()
		end,
		"run_cur_file_exit",
		mode = { "n", "v" },
	},
	["<leader>rf"] = {
		function()
			require("spectre").open_file_search({ select_word = true })
		end,
		"Find <cword> & Replace in current buffer",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>rw"] = {
		function()
			require("spectre").open_visual({ select_word = true })
		end,
		"Find <cword> & Replace in current project",
		mode = { "n", "v" },
		silent = true,
	},
})
