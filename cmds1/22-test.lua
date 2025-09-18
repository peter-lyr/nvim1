local function execute_python_code(code, lua_script_dir)
	-- 将 Lua 脚本所在目录传递给 Python 代码
	local full_code = string.format("lua_script_dir = r'%s'\n", lua_script_dir) .. code

	local tmp_file = vim.fn.tempname() .. ".py"
	local f = io.open(tmp_file, "w", "utf8") -- 显式指定 UTF-8 编码写入
	if not f then
		return { success = false, error = "无法创建临时文件" }
	end
	f:write(full_code)
	f:close()

	local output = {}
	local error_output = {}
	-- 构造 Python 命令（兼容 Windows 路径）
	local python_cmd = '"' .. vim.fn.exepath("python") .. '" ' .. tmp_file

	local job_id = vim.fn.jobstart(python_cmd, {
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(output, line)
				end
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(error_output, line)
				end
			end
		end,
		on_exit = function()
			os.remove(tmp_file)
		end,
		-- 移除不支持的 env 参数
	})

	-- 等待任务完成（最长等待 2 秒）
	vim.fn.jobwait({ job_id }, 2000)

	if #error_output > 0 then
		return { success = false, error = table.concat(error_output, "\n") }
	else
		return { success = true, output = table.concat(output, "\n") }
	end
end

-- 获取当前 Lua 脚本（22-test.lua）所在的目录
local current_lua_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")

-- 调用示例：使用 Lua 传递的真实目录路径
local result = execute_python_code(
	[[
import os
import sys
import importlib.util

# 强制设置 stdout 编码为 UTF-8（解决中文输出乱码）
sys.stdout.reconfigure(encoding='utf-8')

# 中文文件名（必须与实际文件名完全一致）
module_filename = "22-执行命令并获取它的pid.py"

# 拼接完整路径（使用 Lua 传递的正确目录）
module_path = os.path.join(lua_script_dir, module_filename)
module_path = os.path.abspath(module_path)  # 转换为绝对路径

# 打印路径用于调试（可删除）
print(f"尝试加载的模块路径：{module_path}")

# 检查文件是否存在
if not os.path.exists(module_path):
    print(f"错误：文件不存在 - {module_path}")
elif not os.path.isfile(module_path):
    print(f"错误：不是文件 - {module_path}")
else:
    try:
        # 通过路径加载模块
        spec = importlib.util.spec_from_file_location("custom_module", module_path)
        run_and_get_pid = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(run_and_get_pid)
        # 调用模块中的 main 函数
        run_and_get_pid.main()
    except Exception as e:
        print(f"执行模块出错：{str(e)}")
]],
	current_lua_dir
) -- 传递当前 Lua 脚本的目录

print(vim.inspect(result))

-- {
--   output = '尝试加载的模块路径：C:\\Users\\depei_liu\\Dp1\\lazy\\nvim1\\cmds1\\22-执行命令并获取它的pid.py\r\nssssssssss\r\n用法: python 22-执行命令并获取它的pid.py "需要执行的命令"\r\n示例1: python 22-执行命令并获取它的pid.py "calc"\r\n示例2: python 22-执行命令并获取它的pid.py "chcp 65001 & git status & pause"\r',
--   success = true,
-- })
