vim.api.nvim_create_user_command("FormatAhk", function(params)
	for _ = 1, 9 do
		vim.cmd([[
      try
        silent %s/^ \+$//g
      catch
      endtry
      try
        silent %s/; .\+//g
      catch
      endtry
      try
        silent %s/^$\n / /g
      catch
      endtry
      try
        silent g/^\(.*\)$\n\1$/d
      catch
      endtry
      try
        silent %s/::$\n{/:: {
      catch
      endtry
      try
        silent %s/)$\n{/) {
      catch
      endtry
    ]])
	end
end, { nargs = "*" })
