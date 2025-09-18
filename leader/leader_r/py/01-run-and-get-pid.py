import subprocess
import re
import sys
import os
import psutil
import time


def escape_double_quotes(command: str) -> str:
    return command.replace('"', '""')


def is_standalone_app(command: str) -> bool:
    return any(
        app in command.lower()
        for app in ["calc", "notepad", "mspaint", "explorer", "regedit"]
    )


def execute_standalone_app(command: str) -> tuple[int | None, str]:
    try:
        process = subprocess.Popen(
            command, shell=True, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP
        )
        time.sleep(1.5)
        return process.pid, ""
    except Exception as e:
        return None, f"启动失败: {str(e)}"


def execute_command_line(command: str) -> tuple[int | None, str]:
    try:
        wrapped_command = f"cmd /c {escape_double_quotes(command)}"
        wmic_command = f'''wmic process call create "{wrapped_command}"'''
        startupinfo = None
        if os.name == "nt":
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 1
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
            return None, f"执行失败: {result.stderr}"
        pid_match = re.search(r"ProcessId\s*=\s*(\d+)", result.stdout, re.IGNORECASE)
        return (int(pid_match.group(1)), "") if pid_match else (None, "无法获取PID")
    except Exception as e:
        return None, f"异常: {str(e)}"


def get_related_processes(start_pid: int, command: str) -> list[int]:
    if is_standalone_app(command):
        related = []
        if psutil.pid_exists(start_pid):
            try:
                related = [
                    p.pid for p in psutil.Process(start_pid).children(recursive=True)
                ]
            except:
                pass
        app_name = command.split()[0].lower() + ".exe"
        name_matches = [
            p.info["pid"]
            for p in psutil.process_iter(["pid", "name"])
            if p.info["name"] and app_name in p.info["name"].lower()
        ]
        return list(set(related + name_matches))
    else:
        if psutil.pid_exists(start_pid):
            try:
                return [
                    p.pid for p in psutil.Process(start_pid).children(recursive=True)
                ]
            except:
                pass
        return []


def kill_processes(pids: list[int]) -> bool:
    all_success = True
    for pid in pids:
        try:
            if not psutil.pid_exists(pid):
                continue
            proc = psutil.Process(pid)
            proc.terminate()
            try:
                proc.wait(timeout=2)
            except psutil.TimeoutExpired:
                proc.kill()
        except (psutil.NoSuchProcess, Exception):
            all_success = False
    return all_success


def main():
    return "ssss"
    if len(sys.argv) < 2:
        sys.exit(1)
    target_command = " ".join(sys.argv[1:])
    start_pid, _ = (
        execute_standalone_app(target_command)
        if is_standalone_app(target_command)
        else execute_command_line(target_command)
    )
    if not start_pid:
        sys.exit(1)
    related_pids = get_related_processes(start_pid, target_command)
    input()
    success = kill_processes(related_pids)
    if psutil.pid_exists(start_pid):
        success = kill_processes([start_pid]) and success
    if is_standalone_app(target_command):
        app_name = target_command.split()[0].lower() + ".exe"
        remaining = [
            p.info["pid"]
            for p in psutil.process_iter(["pid", "name"])
            if p.info["name"] and app_name in p.info["name"].lower()
        ]
        if remaining:
            success = kill_processes(remaining) and success


if __name__ == "__main__":
    main()
