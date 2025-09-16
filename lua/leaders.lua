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
			{ "<leader>b", desc = "leader_b" },
		},
	},

	-- leader_c
	{
		name = "leader_c",
		dir = Nvim1Leader .. "leader_c",
		keys = {
			{ "<leader>c", desc = "leader_c" },
		},
	},

	-- leader_d
	{
		name = "leader_d",
		dir = Nvim1Leader .. "leader_d",
		keys = {
			{ "<leader>d", desc = "leader_d" },
		},
	},

	-- -- leader_e
	-- {
	--   name = 'leader_e',
	--   dir = Nvim1Leader .. 'leader_e',
	--   keys = {
	--     { '<leader>e', desc = 'leader_e', },
	--   },
	-- },

	-- -- leader_f
	-- {
	--   name = 'leader_f',
	--   dir = Nvim1Leader .. 'leader_f',
	--   keys = {
	--     { '<leader>f', desc = 'leader_f', },
	--   },
	-- },

	-- leader_g
	{
		name = "leader_g",
		dir = Nvim1Leader .. "leader_g",
		keys = {
			{ "<leader>g", desc = "leader_g" },
		},
	},

	-- -- leader_h
	-- {
	--   name = 'leader_h',
	--   dir = Nvim1Leader .. 'leader_h',
	--   keys = {
	--     { '<leader>h', desc = 'leader_h', },
	--   },
	-- },

	-- -- leader_i
	-- {
	--   name = 'leader_i',
	--   dir = Nvim1Leader .. 'leader_i',
	--   keys = {
	--     { '<leader>i', desc = 'leader_i', },
	--   },
	-- },

	-- -- leader_l
	-- {
	--   name = 'leader_l',
	--   dir = Nvim1Leader .. 'leader_l',
	--   keys = {
	--     { '<leader>l', desc = 'leader_l', },
	--   },
	-- },

	-- -- leader_m
	-- {
	--   name = 'leader_m',
	--   dir = Nvim1Leader .. 'leader_m',
	--   keys = {
	--     { '<leader>m', desc = 'leader_m', },
	--   },
	-- },

	-- -- leader_n
	-- {
	--   name = 'leader_n',
	--   dir = Nvim1Leader .. 'leader_n',
	--   keys = {
	--     { '<leader>n', desc = 'leader_n', },
	--   },
	-- },

	-- leader_o
	{
		name = "leader_o",
		dir = Nvim1Leader .. "leader_o",
		keys = {
			{ "<leader>o", desc = "leader_o" },
		},
	},

	-- -- leader_p
	-- {
	--   name = 'leader_p',
	--   dir = Nvim1Leader .. 'leader_p',
	--   keys = {
	--     { '<leader>p', desc = 'leader_p', },
	--   },
	-- },

	-- -- leader_q
	-- {
	--   name = 'leader_q',
	--   dir = Nvim1Leader .. 'leader_q',
	--   keys = {
	--     { '<leader>q', desc = 'leader_q', },
	--   },
	-- },

	-- leader_r
	{
		name = "leader_r",
		dir = Nvim1Leader .. "leader_r",
		keys = {
			{ "<leader>r", desc = "leader_r" },
		},
	},

	-- leader_s
	{
		name = "leader_s",
		dir = Nvim1Leader .. "leader_s",
		keys = {
			{ "<leader>s", desc = "telescope" },
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
	--     { '<leader>t', desc = 'leader_t', },
	--   },
	-- },

	-- -- leader_u
	-- {
	--   name = 'leader_u',
	--   dir = Nvim1Leader .. 'leader_u',
	--   keys = {
	--     { '<leader>u', desc = 'leader_u', },
	--   },
	-- },

	-- -- leader_v
	-- {
	--   name = 'leader_v',
	--   dir = Nvim1Leader .. 'leader_v',
	--   keys = {
	--     { '<leader>v', desc = 'leader_v', },
	--   },
	-- },

	-- leader_w
	{
		name = "leader_w",
		dir = Nvim1Leader .. "leader_w",
		keys = {
			{ "<leader>w", desc = "leader_w" },
		},
	},

	-- leader_x
	{
		name = "leader_x",
		dir = Nvim1Leader .. "leader_x",
		keys = {
			{ "<leader>x", desc = "leader_x" },
		},
	},

	-- -- leader_y
	-- {
	--   name = 'leader_y',
	--   dir = Nvim1Leader .. 'leader_y',
	--   keys = {
	--     { '<leader>y', desc = 'leader_y', },
	--   },
	-- },

	-- -- leader_z
	-- {
	--   name = 'leader_z',
	--   dir = Nvim1Leader .. 'leader_z',
	--   keys = {
	--     { '<leader>z', desc = 'leader_z', },
	--   },
	-- },
}
