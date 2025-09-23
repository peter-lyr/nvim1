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
	["<leader>r<leader>p"] = {
		function()
			R.run_cur_file(nil, nil, 1)
		end,
		"run_cur_file_console_pause-force_cmd",
		mode = { "n", "v" },
	},
	["<leader>r<leader>s"] = {
		function()
			R.run_cur_file_silent_force_cmd()
		end,
		"run_cur_file_silent-force_cmd",
		mode = { "n", "v" },
	},
	["<leader>r<leader>e"] = {
		function()
			R.run_cur_file_exit_force_cmd()
		end,
		"run_cur_file_exit-force_cmd",
		mode = { "n", "v" },
	},
	["<leader>rt"] = {
		function()
			R.stop_cur_file()
		end,
		"stop_cur_file",
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
