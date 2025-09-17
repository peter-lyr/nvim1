<leader>r.优化:连带plugin目录下的lua也source
<leader>r.优化+2:先lua后plugin目录下的lua
<leader>r.优化+3:不存在的lua不source
<leader>ga优化+3:提交信息删除无用信息后写到另一个文件
<leader>ga优化+4:最后一个buffer不quit
<leader>ga优化+5:异步跑git status
<leader>ga优化+6:add_commit_push_edit,<leader>g<leader>as:add_commit_push_edit_status
<leader>g<leader>as:修复vim.notify
<leader>g<leader>as:修复+2:ok
<leader>g<leader>as:优化+1:把async_run_command合并到async_run里去
<leader>g<leader>ai:add_commit_push_cur_line
<leader>ga优化+7:异步跑git status从run_and_silent换成async_run
<leader>gr
<leader>gl:require 'f'.async_run('git log --oneline')
async_run:优化:stdout默认输出到StdOutTxt
<leader>df:删除当前buffer所在文件
<leader>bw:交换打开两个相关联的文件
<leader>ow.:资源管理器打开当前路径
treesitter colorscheme
<leader>db:delete_cur_buffer
增加多个小插件
优化bbye插件的用法
增加commenter插件快捷键
<leader>bm:message_buffer
<leader>b<leader>n:NotificationsClear
10-异步执行结束后回调.lua
11-把yy复制的文本按行拆开放到table里.lua
增加必要的选项
13-执行系统命令而不阻塞.lua
f.lua:优化+1:增加run_and_notify(...)
notify:优化配置+1
lazy.nvim:修复:v10.24.3,解决dir=''的插件加载不了
nvim-qt开启关闭优化
tab用NMAC427/guess-indent.nvim
lsp:参考nvim-lua/kickstart.nvim改好一版
lsp:python支持
lsp:按键映射
lsp:修复:Setup没调用
formatter:all
clangd:testing
17-画圆.py:优化+1
<leader>pg:粘贴系统剪贴板文本
