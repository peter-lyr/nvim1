vim.api.nvim_create_user_command("FormatAhk", function(params)
	vim.cmd([[
    try
      %s/; .\+//g
    catch
    endtry
    try
      %s/^$\n    /    /g
    catch
    endtry
    try
      g/^\(.*\)$\n\1$/d
    catch
    endtry
    try
      %s/::$\n{/:: {
    catch
    endtry
    try
      %s/)$\n{/) {
    catch
    endtry
  ]])
end, { nargs = "*" })
