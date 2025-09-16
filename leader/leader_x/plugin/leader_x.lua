local W = require("leader_w")

require("which-key").register({
	["<leader>x"] = { name = "window.delete" },
	["<leader>xj"] = {
		function()
			W.window_delete("j")
		end,
		"window delete down",
		mode = { "n", "v" },
	},
	["<leader>xk"] = {
		function()
			W.window_delete("k")
		end,
		"window delete up",
		mode = { "n", "v" },
	},
	["<leader>xh"] = {
		function()
			W.window_delete("h")
		end,
		"window delete left",
		mode = { "n", "v" },
	},
	["<leader>xl"] = {
		function()
			W.window_delete("l")
		end,
		"window delete right",
		mode = { "n", "v" },
	},
	["<leader>xt"] = {
		function()
			W.tabclose()
		end,
		"tabclose",
		mode = { "n", "v" },
	},

	-- ['<leader>xx'] = { function() F.bin_xxd() end, 'xxd', mode = { 'n', 'v', }, silent = true, },
	-- ['<leader>x<leader>x'] = { function() F.bin_xxd_sel() end, 'xxd', mode = { 'n', 'v', }, silent = true, },
})
