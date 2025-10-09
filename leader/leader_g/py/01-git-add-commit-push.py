# 接收一个命令行参数作为git commit -F的提交信息文件
# 区分处理已修改文件和未跟踪文件，先提交已修改文件
# 对文件大小进行检查：
# 单个文件超过 500MB 会被跳过并显示警告
# 总大小超过 500MB 时会分多次提交
# 每次提交按文件大小从小到大排序
# 包含错误处理和重试机制：
# git push操作失败时会重试，最多 5 次
# 任何步骤失败都会显示错误信息并退出程序
# 使用方法：
# python git_batch_commit.py commit_message.txt
# 其中commit_message.txt是包含你的提交信息的文件。
# 脚本会自动处理所有未提交文件，按照设定的规则分批次提交和推送。


import os
import subprocess
import sys
import argparse
import time

# 全局统一编码：优先使用UTF-8，适配多语言文本
GLOBAL_ENCODING = "utf-8"
# Windows终端默认编码（用于日志输出适配）
WINDOWS_TERMINAL_ENCODING = "gbk"


def safe_print(text):
    """安全打印文本，自动适配终端编码，避免乱码"""
    try:
        # 优先按终端编码打印（Windows默认GBK）
        print(
            text.encode(WINDOWS_TERMINAL_ENCODING, errors="replace").decode(
                WINDOWS_TERMINAL_ENCODING
            )
        )
    except:
        # 适配失败时用UTF-8打印
        print(text.encode(GLOBAL_ENCODING, errors="replace").decode(GLOBAL_ENCODING))


def run_command(command, check=True):
    """执行shell命令，统一UTF-8编码，返回结果"""
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=check,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding=GLOBAL_ENCODING,  # 命令输出强制UTF-8解码
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        safe_print(f"命令执行错误: {e.stderr}")  # 用安全打印避免错误信息乱码
        return False, e.stderr
    except UnicodeDecodeError:
        # 极端情况：命令输出是GBK， fallback到GBK解码
        try:
            result = subprocess.run(
                command,
                shell=True,
                check=check,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding=WINDOWS_TERMINAL_ENCODING,
            )
            return True, result.stdout
        except Exception as e:
            safe_print(f"编码解码失败: {str(e)}")
            return False, str(e)
    except Exception as e:
        safe_print(f"命令运行异常: {str(e)}")
        return False, str(e)


def get_uncommitted_files():
    """获取未提交文件，安全处理结果避免None"""
    # 获取已修改文件
    success, modified = run_command("git diff --name-only")
    modified = modified if success else ""  # 确保非None

    # 获取未跟踪文件
    success, untracked = run_command("git ls-files --others --exclude-standard")
    untracked = untracked if success else ""  # 确保非None

    # 过滤空文件路径
    modified_files = [f.strip() for f in modified.splitlines() if f.strip()]
    untracked_files = [f.strip() for f in untracked.splitlines() if f.strip()]

    return modified_files, untracked_files


def get_file_size(file_path):
    """获取文件大小，安全处理路径乱码"""
    try:
        # 路径若有特殊字符，按UTF-8解码（避免路径乱码导致获取失败）
        file_path = file_path.encode(GLOBAL_ENCODING).decode(GLOBAL_ENCODING)
        return os.path.getsize(file_path)
    except OSError as e:
        safe_print(f"警告：无法获取文件大小 {file_path}，错误: {str(e)}")
        return 0


def commit_files(files, commit_msg_file):
    """提交文件，处理路径含特殊字符的情况"""
    if not files:
        safe_print("没有文件需要提交")
        return True

    # 文件名用引号包裹，避免空格/特殊字符问题
    files_quoted = [f'"{f}"' for f in files]
    add_cmd = f'git add {" ".join(files_quoted)}'
    success, output = run_command(add_cmd)
    if not success:
        safe_print(f"添加文件失败: {output}")
        return False

    # 提交命令：文件路径用引号包裹
    commit_cmd = f'git commit -F "{commit_msg_file}"'
    success, output = run_command(commit_cmd)
    if not success:
        safe_print(f"提交失败: {output}")
        return False

    safe_print(f"成功提交 {len(files)} 个文件")
    return True


def push_with_retry(max_retries=5):
    """推送重试，带等待间隔"""
    for i in range(max_retries):
        safe_print(f"正在推送 (尝试 {i+1}/{max_retries})...")
        success, output = run_command("git push")
        if success:
            safe_print("推送成功")
            return True
        safe_print(f"推送失败: {output}")
        if i < max_retries - 1:
            safe_print("等待2秒后重试...")
            time.sleep(2)

    safe_print(f"达到最大重试次数 ({max_retries})，推送失败")
    return False


def main():
    parser = argparse.ArgumentParser(description="批量提交Git文件（解决乱码版）")
    parser.add_argument("commit_msg_file", help="包含提交信息的文件路径（UTF-8编码）")
    args = parser.parse_args()

    commit_msg_file = args.commit_msg_file
    # 检查文件是否存在
    if not os.path.exists(commit_msg_file):
        safe_print(f"错误：提交信息文件 {commit_msg_file} 不存在")
        sys.exit(1)

    # 处理提交信息文件：用UTF-8文本模式读写，过滤注释和空行（核心修复乱码点）
    temp_commit_file = f"{commit_msg_file}.tmp"
    push_allow = False
    try:
        # 用UTF-8读取原文件（避免二进制模式导致的隐性编码问题）
        with open(commit_msg_file, "rt", encoding=GLOBAL_ENCODING) as f:
            lines = f.readlines()

        # 过滤注释（# 开头）和空行，用UTF-8写入临时文件
        with open(temp_commit_file, "wt", encoding=GLOBAL_ENCODING) as f:
            for line in lines:
                line_stripped = line.strip()
                if line_stripped.startswith("#") or not line_stripped:
                    continue
                f.write(f"{line_stripped}\n")
                push_allow = True

        if not push_allow:
            safe_print(
                f"错误：提交信息文件 {commit_msg_file} 内容为空（已过滤注释和空行）"
            )
            os.remove(temp_commit_file)
            sys.exit(2)

    except UnicodeDecodeError:
        safe_print(
            f"错误：提交信息文件 {commit_msg_file} 不是UTF-8编码，请转换编码后重试"
        )
        sys.exit(1)
    except Exception as e:
        safe_print(f"处理提交信息文件失败: {str(e)}")
        if os.path.exists(temp_commit_file):
            os.remove(temp_commit_file)
        sys.exit(1)

    # 配置参数
    MAX_BATCH_SIZE = 500 * 1024 * 1024  # 500MB
    MAX_SINGLE_FILE_SIZE = 500 * 1024 * 1024  # 单个文件最大500MB

    # 获取未提交文件
    modified_files, untracked_files = get_uncommitted_files()
    safe_print(
        f"发现 {len(modified_files)} 个已修改文件，{len(untracked_files)} 个未跟踪文件"
    )

    # 提交已修改文件
    if modified_files:
        safe_print(f"正在提交 {len(modified_files)} 个已修改文件...")
        if commit_files(modified_files, temp_commit_file):
            if not push_with_retry():
                safe_print("提交已修改文件后推送失败，程序退出")
                os.remove(temp_commit_file)
                sys.exit(1)
        else:
            safe_print("提交已修改文件失败，程序退出")
            os.remove(temp_commit_file)
            sys.exit(1)

    # 无未跟踪文件则退出
    if not untracked_files:
        safe_print("没有未跟踪文件需要提交")
        os.remove(temp_commit_file)
        sys.exit(0)

    # 过滤过大文件
    filtered_files = []
    for file in untracked_files:
        file_size = get_file_size(file)
        if file_size > MAX_SINGLE_FILE_SIZE:
            safe_print(
                f"警告：文件 {file} 大小为 {file_size/1024/1024:.2f}MB，超过500MB，已跳过"
            )
            continue
        filtered_files.append((file, file_size))

    # 按文件大小排序
    filtered_files.sort(key=lambda x: x[1])
    safe_print(f"过滤后剩余 {len(filtered_files)} 个未跟踪文件需要提交")

    # 分批次提交
    current_batch = []
    current_size = 0
    for file, size in filtered_files:
        if current_size + size > MAX_BATCH_SIZE:
            if current_batch:
                safe_print(
                    f"提交当前批次（{len(current_batch)} 个文件，总大小 {current_size/1024/1024:.2f}MB）..."
                )
                if commit_files(current_batch, temp_commit_file):
                    if not push_with_retry():
                        safe_print("推送失败，程序退出")
                        os.remove(temp_commit_file)
                        sys.exit(1)
                else:
                    safe_print("提交失败，程序退出")
                    os.remove(temp_commit_file)
                    sys.exit(1)
                # 重置批次
                current_batch = []
                current_size = 0

        current_batch.append(file)
        current_size += size

    # 提交最后一批
    if current_batch:
        safe_print(
            f"提交最后一批（{len(current_batch)} 个文件，总大小 {current_size/1024/1024:.2f}MB）..."
        )
        if commit_files(current_batch, temp_commit_file):
            if not push_with_retry():
                safe_print("推送失败，程序退出")
                os.remove(temp_commit_file)
                sys.exit(1)
        else:
            safe_print("提交失败，程序退出")
            os.remove(temp_commit_file)
            sys.exit(1)

    # 清理临时文件
    os.remove(temp_commit_file)
    safe_print("所有文件提交完成")


if __name__ == "__main__":
    main()
