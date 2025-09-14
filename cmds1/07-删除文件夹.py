import os
import errno
import shutil
import stat

def handle_remove_readonly(func, path, exc):
    """处理只读文件的删除"""
    excvalue = exc[1]
    if func in (os.rmdir, os.remove, os.unlink) and excvalue.errno == errno.EACCES:
        # 修改文件权限
        os.chmod(path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)  # 赋予读写权限
        func(path)  # 再次尝试删除
    else:
        raise

def delete_non_empty_dir(directory):
    """
    删除非空目录及其所有内容
    参数:
        directory: 要删除的目录路径
    """
    if not os.path.exists(directory):
        print(f"目录不存在: {directory}")
        return
    if not os.path.isdir(directory):
        print(f"不是一个目录: {directory}")
        return
    try:
        # 递归删除目录及其内容
        shutil.rmtree(directory, onerror=handle_remove_readonly)
        print(f"成功删除目录: {directory}")
    except PermissionError:
        print(f"权限错误: 无法删除目录 {directory}")
    except OSError as e:
        print(f"删除目录时出错: {e}")
