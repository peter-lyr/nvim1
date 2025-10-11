local G = {}

function G.commit_info_txt()
	return Dp1Temp .. vim.fn.strftime("\\commit-info-%y%m%d-%H%M%S.txt")
end

local function get_py(py)
	local info = debug.getinfo(1, "S")
	local relative_path = info.source:sub(2)
	relative_path = require("f").rep(relative_path)
	return vim.fn.fnamemodify(relative_path, ":p:h:h") .. "\\py\\" .. py
end

function G.add_commit_push_do(py, file)
	require("f").run_and_notify_title_on_exit_err_pty("git add commit push", function(exit_code, signal, output_file)
		vim.fn.delete(file, "rf")
	end, function(errors)
		local message = table.concat(errors, "\n")
		if require("f").in_str(".git/index.lock': File exists.", message) then
			_G.add_commit_push_retry_cnt = _G.add_commit_push_retry_cnt - 1
			require("f").fidget_notify("_G.add_commit_push_retry_cnt: %d", _G.add_commit_push_retry_cnt)
			if _G.add_commit_push_retry_cnt <= 0 then
				return
			end
			G.add_commit_push_do(py, file)
		end
	end, "python %s %s", py, file)
end

function G.add_commit_push_file(file)
	if not require("f").is_file_exists(file) then
		return
	end
	local git_add_commit_push_py = get_py("git-auto-commit.py")
	require("f").run_and_notify("git status")
	_G.add_commit_push_retry_cnt = 50
	G.add_commit_push_do(git_add_commit_push_py, file)
end

function G.add_commit_push_infos(infos)
	if not require("f").is(infos) then
		return
	end
	infos = require("f").to_table(infos)
	require("f").write_lines_to_file(infos, G.commit_info_txt())
	G.add_commit_push_file(G.commit_info_txt())
end

function G.write_TempTxt_and_quit_and_add_commit_push()
	require("f").write_lines_to_file({}, G.commit_info_txt())
	require("f").cmd("bw %s", G.commit_info_txt())
	local reg = vim.fn.getreg("/")
	require("f").cmd_try("g/^#.*/d")
	require("f").cmd_try([[g/^\s*$/d]])
	require("f").cmd_try([[%s/\s\+/ /g]])
	require("f").cmd_try([[%s/\s\+$//]])
	vim.fn.setreg("/", reg)
	require("f").cmd("silent w! %s", G.commit_info_txt())
	if not require("f").is(require("f").is_cur_last_win()) then
		vim.cmd("silent q")
	end
	for _ = 1, 1000 do
		local lines = require("f").read_lines_from_file(G.commit_info_txt())
		if #lines > 0 then
			break
		end
	end
	G.add_commit_push_file(G.commit_info_txt())
	vim.keymap.del({ "n", "v" }, "<cr><cr>", { buffer = vim.g.bufnr })
end

function G.add_commit_push_edit_status()
	require("f").async_run("git status", {
		title = "Git Status",
		on_exit = function(exit_code, signal, file)
			print("Command exited with code: " .. exit_code .. ", output in " .. file)
			vim.cmd("new")
			local status = require("f").read_lines_from_file(file)
			for i = 1, #status do
				status[i] = "# " .. status[i]
			end
			vim.fn.setline(".", status)
			vim.cmd("norm G")
			-- require("f").set_ft("c")
			vim.g.bufnr = vim.fn.bufnr()
			vim.keymap.set({ "n", "v" }, "<cr><cr>", function()
				G.write_TempTxt_and_quit_and_add_commit_push()
			end, { desc = "write_TempTxt_and_quit_and_add_commit_push", buffer = vim.g.bufnr })
		end,
	})
end

function G.add_commit_push_edit()
	vim.cmd("new")
	vim.g.bufnr = vim.fn.bufnr()
	vim.keymap.set({ "n", "v" }, "<cr><cr>", function()
		G.write_TempTxt_and_quit_and_add_commit_push()
	end, { desc = "write_TempTxt_and_quit_and_add_commit_push", buffer = vim.g.bufnr })
end

function G.add_commit_push_yank()
	G.add_commit_push_infos(require("f").yank_to_lines_table())
end

function G.add_commit_push_cword()
	G.add_commit_push_infos(vim.fn.expand("<cword>"))
end

function G.add_commit_push_cWORD()
	G.add_commit_push_infos(vim.fn.expand("<cWORD>"))
end

function G.add_commit_push_cur_line()
	G.add_commit_push_infos(require("f").trim(vim.fn.getline(".")))
end

function G.add_commit_push_bufname()
	G.add_commit_push_infos(vim.fn.bufname())
end

function G.reset_hunk()
	require("gitsigns").reset_hunk()
end

function G.reset_hunk_v()
	require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end

function G.git_reset_buffer()
	require("gitsigns").reset_buffer()
end

function G.git_reset_hard()
	require("f").run_and_notify_title_on_exit("git reset --hard", function()
		require("f").windo("e!")
	end, "git reset --hard")
end

function G.git_reset_clean_fd()
	require("f").run_and_notify_title_on_exit("git clean -fd", function()
		require("f").windo("e!")
	end, "git clean -fd")
end

function G.pull()
	require("f").run_and_notify_pty("git pull")
end

function G.push()
	require("f").run_and_notify_pty("git push")
end

function G.log()
	require("f").run_and_notify("git log")
end

function G.log_oneline()
	require("f").run_and_notify("git log --oneline --graph --all")
end

function G.status()
	require("f").run_and_notify("git status")
end

function G.diffview_stash()
	vim.cmd([[DiffviewFileHistory --walk-reflogs --range=stash]])
end

function G.diffview_open()
	vim.cmd([[DiffviewOpen]])
end

return G
