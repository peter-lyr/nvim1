local O = require("leader_o")

require("which-key").register({
	["<leader>o"] = { name = "leader_o" },
	["<leader>ow"] = {
		function()
			O.open_work_md()
		end,
		"open: work.md",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>od"] = {
		function()
			O.open_work_summary_day()
		end,
		"open: work_summary_day.md",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>oi"] = {
		function()
			O.open_init_lua()
		end,
		"open: init.lua",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>ot"] = {
		function()
			O.open_temp_txt()
		end,
		"open: temp.txt",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>o<leader>t"] = {
		function()
			O.open_temp_txt_txt()
		end,
		"open: temp.txt.txt",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>o<leader>s"] = {
		function()
			O.open_stdout_txt()
		end,
		"open: stdout.txt",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>os"] = { name = "open: explorer" },
	["<leader>os."] = {
		function()
			O.open_cur_dir()
		end,
		"explorer open: cur_dir",
		mode = { "n", "v" },
		silent = true,
	},
	["<leader>osw"] = {
		function()
			O.open_cwd()
		end,
		"explorer open: cwd",
		mode = { "n", "v" },
		silent = true,
	},
})
