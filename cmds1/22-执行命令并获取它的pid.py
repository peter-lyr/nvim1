# C:\Users\depei_liu\Dp1\lazy\nvim1\cmds1\02-ahk>wmic process call create "cmd /c cd C:\Users\depei_liu\Dp1\lazy\nvim1 & git status & pause"
# Executing (Win32_Process)->Create()
# Method execution successful.
# Out Parameters:
# instance of __PARAMETERS
# {
#         ProcessId = 19172;
#         ReturnValue = 0;
# };
#
# C:\Users\depei_liu\Dp1\lazy\nvim1\cmds1\02-ahk>taskkill /f /pid 19172
# SUCCESS: The process with PID 19172 has been terminated.

import subprocess
import re
import logging

# 配置日志，输出时间、级别和信息，便于跟踪
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def execute_command(command: str) -> tuple[str, str, int]:
    """
    执行外部命令，返回标准输出、标准错误和返回码

    参数:
        command: 待执行的命令字符串（支持复杂命令如管道、多步骤操作）

    返回:
        tuple: (stdout: 标准输出字符串, stderr: 标准错误字符串, returncode: 命令返回码)
    """
    try:
        logging.info(f"正在执行命令: {command}")
        # 执行命令，捕获 stdout/stderr，设置超时防止无限挂起
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,  # 捕获标准输出
            stderr=subprocess.PIPE,  # 捕获标准错误
            text=True,  # 输出转为字符串（而非字节流）
            shell=True,  # 允许在shell中执行命令（支持&、|等符号）
            timeout=60,  # 超时时间60秒，可根据需求调整
        )
        # 返回输出和返回码（returncode=0表示成功）
        return result.stdout, result.stderr, result.returncode

    except subprocess.TimeoutExpired:
        # 命令超时异常
        error_msg = "命令执行超时（超过60秒）"
        logging.error(error_msg)
        return "", error_msg, -1  # 返回码-1标识超时

    except Exception as e:
        # 其他未知异常（如命令不存在、权限不足等）
        error_msg = f"命令执行异常: {str(e)}"
        logging.error(error_msg)
        return "", error_msg, -2  # 返回码-2标识未知异常


def extract_pid(output: str) -> int | None:
    """
    从 `wmic process call create` 的输出中提取进程PID（ProcessId）

    参数:
        output: 命令的标准输出字符串（需包含"ProcessId = 数字"格式）

    返回:
        int: 提取到的PID（整数）；若未找到则返回None
    """
    # 正则表达式：匹配 "ProcessId = " 后的数字（支持前后有空格的情况）
    pid_pattern = r"ProcessId\s*=\s*(\d+)"
    # 搜索匹配结果（忽略大小写，增强兼容性）
    match = re.search(pid_pattern, output, re.IGNORECASE)

    if match:
        # 提取捕获组1（数字部分）并转为整数
        pid = int(match.group(1))
        logging.info(f"成功从输出中提取PID: {pid}")
        return pid
    else:
        logging.warning("未在命令输出中找到PID（检查输出是否包含'ProcessId = 数字'）")
        return None


def main():
    """主函数：串联命令执行、结果处理、PID提取的完整流程"""
    # 目标命令说明：
    # 1. wmic process call create：创建新进程并返回PID
    # 2. 内部cmd命令：
    #    - chcp 65001：设置控制台编码为UTF-8（避免中文乱码）
    #    - cd 路径：切换到git仓库目录
    #    - git status：查询git仓库状态
    #    - pause：暂停控制台（防止进程执行完立即关闭，便于查看结果）
    target_command = '''wmic process call create "cmd /c chcp 65001 & cd C:\\Users\\depei_liu\\Dp1\\lazy\\nvim1 & git status & pause"'''

    # 1. 执行命令，获取输出和返回码
    stdout, stderr, returncode = execute_command(target_command)

    # 2. 根据返回码判断命令是否真正成功
    if returncode == 0:
        logging.info("命令执行成功（返回码=0）")
        print("=" * 50)
        print("【命令执行成功】")
        print("标准输出（stdout）：")
        print(stdout)

        # 若stderr有内容，仅作为“额外信息”显示（非错误）
        if stderr:
            print("\n【额外提示（stderr）】：")
            print(stderr)

        # 3. 提取并显示PID
        pid = extract_pid(stdout)
        if pid:
            print(f"\n【提取到的进程PID】：{pid}")
        else:
            print("\n【PID提取失败】：未在输出中找到ProcessId")
        print("=" * 50)

    else:
        # 返回码非0，判定为命令执行失败
        logging.error(f"命令执行失败（返回码={returncode}）")
        print("=" * 50)
        print(f"【命令执行失败】（返回码={returncode}）")
        print("错误信息（stderr）：")
        print(stderr)
        print("=" * 50)


if __name__ == "__main__":
    main()
