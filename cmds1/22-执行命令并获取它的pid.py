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
import sys
import os

# 配置日志
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def escape_double_quotes(command: str) -> str:
    """转义命令中的双引号为""（适应Windows命令行规则）"""
    return command.replace('"', '""')


def execute_command(
    wmic_command: str, show_window: bool = False
) -> tuple[str, str, int]:
    """
    执行命令（兼容低版本Python），根据需求显示/隐藏窗口

    参数:
        wmic_command: 完整的wmic命令
        show_window: 是否显示窗口（含交互操作如pause时需要显示）
    """
    try:
        logging.info(f"执行完整命令: {wmic_command}")

        # 配置窗口显示（兼容低版本Python的写法）
        startupinfo = None
        if os.name == "nt":
            startupinfo = subprocess.STARTUPINFO()
            if not show_window:
                # 隐藏窗口（SW_HIDE = 0）
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                startupinfo.wShowWindow = 0  # 0表示隐藏窗口

        result = subprocess.run(
            wmic_command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True,
            timeout=300,
            startupinfo=startupinfo,  # 低版本用startupinfo替代creation_flags
        )
        return result.stdout, result.stderr, result.returncode

    except subprocess.TimeoutExpired:
        return "", "命令执行超时（超过5分钟）", -1
    except Exception as e:
        return "", f"执行异常: {str(e)}", -2


def extract_pid(output: str) -> int | None:
    """提取进程PID"""
    if not output:
        logging.warning("无输出，无法提取PID")
        return None
    pid_match = re.search(r"ProcessId\s*=\s*(\d+)", output, re.IGNORECASE)
    return int(pid_match.group(1)) if pid_match else None


def kill_process(pid: int) -> bool:
    """通过PID强制关闭进程及所有子进程"""
    try:
        # /t: 终止指定进程及其所有子进程
        result = subprocess.run(
            f"taskkill /f /t /pid {pid}",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True,
        )
        if result.returncode == 0:
            logging.info(f"成功关闭PID={pid}及其子进程")
            return True
        else:
            logging.error(f"关闭失败: {result.stderr}")
            return False
    except Exception as e:
        logging.error(f"关闭进程时出错: {str(e)}")
        return False


def main():
    if len(sys.argv) < 2:
        print(
            '用法: python compatible_execute.py "需要执行的命令（如git status & pause）"'
        )
        print('示例: python compatible_execute.py "git status & pause"')
        # python 22-执行命令并获取它的pid.py "chcp 65001 & cd ""C:\Users\depei_liu\Dp1\lazy\nvim1"" & git status & pause"
        # python 22-执行命令并获取它的pid.py "notepad" # 这个命令会多一个cmd窗口
        sys.exit(1)

    target_command = " ".join(sys.argv[1:])
    logging.info(f"目标命令: {target_command}")

    # 用cmd /c包裹命令，确保&和pause正确生效
    wrapped_command = f"cmd /c {escape_double_quotes(target_command)}"
    wmic_command = f'''wmic process call create "{wrapped_command}"'''

    # 执行命令（显示窗口以便交互）
    stdout, stderr, returncode = execute_command(wmic_command, show_window=True)

    if returncode != 0:
        print(f"启动命令失败: {stderr}")
        sys.exit(1)

    pid = extract_pid(stdout)
    if not pid:
        print("未获取到PID，无法继续")
        sys.exit(1)

    print(f"成功启动命令，PID={pid}（请在弹出窗口中操作，完成后按Enter关闭）")
    input("按Enter键关闭所有相关进程...")

    if kill_process(pid):
        print(f"PID={pid}及其相关进程已成功关闭")
    else:
        print(f"关闭PID={pid}失败，请手动结束进程")


if __name__ == "__main__":
    main()
