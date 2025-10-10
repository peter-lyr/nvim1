return {

	-- -- leader_a
	-- {
	--   name = 'leader_a',
	--   dir = Nvim1Leader .. 'leader_a',
	--   keys = {
	--     { '<leader>a', desc = 'leader_a', },
	--   },
	-- },

	-- leader_b
	{
		name = "leader_b",
		dir = Nvim1Leader .. "leader_b",
		keys = {
			{ "<leader>b", desc = "leader_b", mode = { "n", "v" } },
		},
	},

	-- leader_c
	{
		name = "leader_c",
		dir = Nvim1Leader .. "leader_c",
		keys = {
			{ "<leader>c", desc = "leader_c", mode = { "n", "v" } },
		},
	},

	-- leader_d
	{
		name = "leader_d",
		dir = Nvim1Leader .. "leader_d",
		keys = {
			{ "<leader>d", desc = "leader_d", mode = { "n", "v" } },
		},
	},

	-- -- leader_e
	-- {
	--   name = "leader_e",
	--   dir = Nvim1Leader .. "leader_e",
	--   keys = {
	--     { "<leader>e", desc = "leader_e", mode = { "n", "v" } },
	--   },
	-- },

	-- leader_f
	{
		name = "leader_f",
		dir = Nvim1Leader .. "leader_f",
		keys = {
			{ "<leader>f", desc = "leader_f", mode = { "n", "v" } },
		},
	},

	-- leader_g
	{
		name = "leader_g",
		dir = Nvim1Leader .. "leader_g",
		keys = {
			{ "<leader>g", desc = "leader_g", mode = { "n", "v" } },
		},
	},

	-- -- leader_h
	-- {
	--   name = "leader_h",
	--   dir = Nvim1Leader .. "leader_h",
	--   keys = {
	--     { "<leader>h", desc = "leader_h", mode = { "n", "v" } },
	--   },
	-- },

	-- -- leader_i
	-- {
	--   name = "leader_i",
	--   dir = Nvim1Leader .. "leader_i",
	--   keys = {
	--     { "<leader>i", desc = "leader_i", mode = { "n", "v" } },
	--   },
	-- },

	-- -- leader_l
	-- {
	--   name = "leader_l",
	--   dir = Nvim1Leader .. "leader_l",
	--   keys = {
	--     { "<leader>l", desc = "leader_l", mode = { "n", "v" } },
	--   },
	-- },

	-- -- leader_m
	-- {
	--   name = "leader_m",
	--   dir = Nvim1Leader .. "leader_m",
	--   keys = {
	--     { "<leader>m", desc = "leader_m", mode = { "n", "v" } },
	--   },
	-- },

	-- -- leader_n
	-- {
	--   name = "leader_n",
	--   dir = Nvim1Leader .. "leader_n",
	--   keys = {
	--     { "<leader>n", desc = "leader_n", mode = { "n", "v" } },
	--   },
	-- },

	-- leader_o
	{
		name = "leader_o",
		dir = Nvim1Leader .. "leader_o",
		keys = {
			{ "<leader>o", desc = "leader_o", mode = { "n", "v" } },
		},
	},

	-- leader_p
	{
		name = "leader_p",
		dir = Nvim1Leader .. "leader_p",
		keys = {
			{ "<leader>p", desc = "leader_p", mode = { "n", "v" } },
		},
	},

	-- -- leader_q
	-- {
	--   name = 'leader_q',
	--   dir = Nvim1Leader .. 'leader_q',
	--   keys = {
	--     { '<leader>q', desc = 'leader_q', mode = { "n", "v" }, },
	--   },
	-- },

	-- leader_r
	{
		name = "leader_r",
		dir = Nvim1Leader .. "leader_r",
		cmd = { "Run", "RunPty" },
		keys = {
			{ "<leader>r", desc = "leader_r", mode = { "n", "v" } },
			{
				"<leader>;",
				":<c-u>RunPty",
				desc = "RunPty",
				mode = { "n", "v" },
			},
		},
	},

	-- leader_s
	{
		name = "leader_s",
		dir = Nvim1Leader .. "leader_s",
		keys = {
			{ "<leader>s", desc = "telescope", mode = { "n", "v" } },
			{
				"<leader><leader>",
				"<cmd>Telescope find_files<cr>",
				desc = "find_files",
				mode = { "n", "v" },
			},
			{
				"<leader>/",
				"<cmd>Telescope current_buffer_fuzzy_find<cr>",
				desc = "current_buffer_fuzzy_find",
				mode = { "n", "v" },
			},
		},
	},

	-- -- leader_t
	-- {
	--   name = 'leader_t',
	--   dir = Nvim1Leader .. 'leader_t',
	--   keys = {
	--     { '<leader>t', desc = 'leader_t', mode = { "n", "v" }, },
	--   },
	-- },

	-- -- leader_u
	-- {
	--   name = 'leader_u',
	--   dir = Nvim1Leader .. 'leader_u',
	--   keys = {
	--     { '<leader>u', desc = 'leader_u', mode = { "n", "v" }, },
	--   },
	-- },

	-- -- leader_v
	-- {
	--   name = 'leader_v',
	--   dir = Nvim1Leader .. 'leader_v',
	--   keys = {
	--     { '<leader>v', desc = 'leader_v', mode = { "n", "v" }, },
	--   },
	-- },

	-- leader_w
	{
		name = "leader_w",
		dir = Nvim1Leader .. "leader_w",
		keys = {
			{ "<leader>w", desc = "leader_w", mode = { "n", "v" } },
		},
	},

	-- leader_x
	{
		name = "leader_x",
		dir = Nvim1Leader .. "leader_x",
		keys = {
			{ "<leader>x", desc = "leader_x", mode = { "n", "v" } },
		},
	},

	-- -- leader_y
	-- {
	--   name = 'leader_y',
	--   dir = Nvim1Leader .. 'leader_y',
	--   keys = {
	--     { '<leader>y', desc = 'leader_y', mode = { "n", "v" }, },
	--   },
	-- },

	-- -- leader_z
	-- {
	--   name = 'leader_z',
	--   dir = Nvim1Leader .. 'leader_z',
	--   keys = {
	--     { '<leader>z', desc = 'leader_z', mode = { "n", "v" }, },
	--   },
	-- },
}
