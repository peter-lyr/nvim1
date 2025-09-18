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
import psutil
import time

# 配置日志
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def escape_double_quotes(command: str) -> str:
    """转义命令中的双引号为""（适应Windows命令行规则）"""
    return command.replace('"', '""')


def is_standalone_app(command: str) -> bool:
    """判断是否为独立应用程序（无需通过cmd运行）"""
    standalone_apps = ["calc", "notepad", "mspaint", "explorer", "regedit"]
    cmd_lower = command.lower()
    return any(app in cmd_lower for app in standalone_apps)


def execute_standalone_app(command: str) -> tuple[int | None, str]:
    """直接启动独立应用程序（不通过cmd中转）"""
    try:
        logging.info(f"启动独立应用: {command}")
        # 直接启动应用，不通过cmd，避免父进程提前退出
        process = subprocess.Popen(
            command, shell=True, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP
        )
        # 等待应用完全启动（关键：给足时间让进程创建完成）
        time.sleep(1.5)
        return process.pid, ""
    except Exception as e:
        return None, f"启动应用失败: {str(e)}"


def execute_command_line(command: str) -> tuple[int | None, str]:
    """执行命令行交互命令（通过cmd中转）"""
    try:
        logging.info(f"执行命令行命令: {command}")
        wrapped_command = f"cmd /c {escape_double_quotes(command)}"
        wmic_command = f'''wmic process call create "{wrapped_command}"'''

        startupinfo = None
        if os.name == "nt":
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 1  # 显示窗口

        result = subprocess.run(
            wmic_command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True,
            timeout=300,
            startupinfo=startupinfo,
        )

        if result.returncode != 0:
            return None, f"命令执行失败: {result.stderr}"

        # 提取cmd进程PID
        pid_match = re.search(r"ProcessId\s*=\s*(\d+)", result.stdout, re.IGNORECASE)
        if not pid_match:
            return None, "无法提取进程PID"

        return int(pid_match.group(1)), ""
    except Exception as e:
        return None, f"执行异常: {str(e)}"


def get_related_processes(start_pid: int, command: str) -> list[int]:
    """获取所有相关进程（针对不同类型命令采用不同策略）"""
    if is_standalone_app(command):
        # 独立应用：获取所有后代进程 + 按名称匹配
        related = []
        # 1. 先找直接后代
        if psutil.pid_exists(start_pid):
            try:
                parent = psutil.Process(start_pid)
                related = parent.children(recursive=True)
                related = [p.pid for p in related]
            except Exception as e:
                logging.warning(f"获取后代进程失败: {str(e)}")

        # 2. 再按名称补充（应对父进程已退出的情况）
        app_name = command.split()[0].lower() + ".exe"
        name_matches = [
            p.info["pid"]
            for p in psutil.process_iter(["pid", "name"])
            if p.info["name"] and app_name in p.info["name"].lower()
        ]

        # 合并去重
        return list(set(related + name_matches))
    else:
        # 命令行命令：获取所有后代进程
        if psutil.pid_exists(start_pid):
            try:
                parent = psutil.Process(start_pid)
                return [p.pid for p in parent.children(recursive=True)]
            except Exception as e:
                logging.warning(f"获取命令行子进程失败: {str(e)}")
        return []


def kill_processes(pids: list[int]) -> bool:
    """终止指定进程列表"""
    all_success = True
    for pid in pids:
        try:
            if not psutil.pid_exists(pid):
                logging.warning(f"进程PID={pid}已不存在")
                continue

            proc = psutil.Process(pid)
            proc_name = proc.name()

            # 先尝试正常终止
            proc.terminate()
            try:
                proc.wait(timeout=2)
                logging.info(f"成功关闭进程PID={pid}（{proc_name}）")
            except psutil.TimeoutExpired:
                # 超时则强制终止
                proc.kill()
                logging.info(f"强制关闭进程PID={pid}（{proc_name}）")
        except psutil.NoSuchProcess:
            logging.warning(f"进程PID={pid}已退出")
        except Exception as e:
            logging.error(f"关闭PID={pid}失败: {str(e)}")
            all_success = False
    return all_success


def main():
    if len(sys.argv) < 2:
        print('用法: python 22-执行命令并获取它的pid.py "需要执行的命令"')
        print('示例1: python 22-执行命令并获取它的pid.py "calc"')
        print(
            '示例2: python 22-执行命令并获取它的pid.py "chcp 65001 & git status & pause"'
        )
        # python 22-执行命令并获取它的pid.py "chcp 65001 & cd ""C:\Users\depei_liu\Dp1\lazy\nvim1"" & git status & pause"
        # python 22-执行命令并获取它的pid.py "notepad"
        # python 22-执行命令并获取它的pid.py "calc" # 无法kill掉calc
        sys.exit(1)

    target_command = " ".join(sys.argv[1:])
    logging.info(f"目标命令: {target_command}")

    # 区分处理独立应用和命令行命令
    if is_standalone_app(target_command):
        start_pid, error = execute_standalone_app(target_command)
    else:
        start_pid, error = execute_command_line(target_command)

    if not start_pid:
        print(f"启动失败: {error}")
        sys.exit(1)

    # 获取所有相关进程（关键：在用户操作前就获取）
    related_pids = get_related_processes(start_pid, target_command)
    logging.info(f"相关进程PID列表: {related_pids}")

    print(f"成功启动命令，基准PID={start_pid}（请在弹出窗口中操作，完成后按Enter关闭）")
    input("按Enter键关闭所有相关进程...")

    # 先关闭相关进程（应用程序本体）
    success = kill_processes(related_pids)

    # 再关闭启动进程（独立应用的启动器或命令行的cmd）
    if psutil.pid_exists(start_pid):
        success = kill_processes([start_pid]) and success
    else:
        logging.info(f"启动进程PID={start_pid}已自动退出")

    # 最终检查：确保没有残留
    if is_standalone_app(target_command):
        app_name = target_command.split()[0].lower() + ".exe"
        remaining = [
            p.info["pid"]
            for p in psutil.process_iter(["pid", "name"])
            if p.info["name"] and app_name in p.info["name"].lower()
        ]
        if remaining:
            logging.warning(f"发现残留进程，尝试再次关闭: {remaining}")
            success = kill_processes(remaining) and success

    if success:
        print("所有相关进程已成功关闭")
    else:
        print("部分进程关闭失败，请手动检查")


if __name__ == "__main__":
    main()
