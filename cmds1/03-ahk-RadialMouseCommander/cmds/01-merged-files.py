import os


def merge_files(source_dir, target_dir, file_extension, output_filename):
    """
    将源文件夹及其所有子目录下所有指定类型的文件内容合并到目标文件夹下的一个文件中，排除目标文件夹内的文件

    参数:
    source_dir (str): 源文件夹路径，从中读取文件
    target_dir (str): 目标文件夹路径，合并后的文件将保存到这里
    file_extension (str): 要合并的文件类型，如 'txt'、'py' 等（不带点）
    output_filename (str): 合并后的文件名
    """
    try:
        # 确保目标文件夹存在，如果不存在则创建
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)

        # 构建输出文件的完整路径
        output_path = os.path.join(target_dir, output_filename)

        # 获取目标文件夹的绝对路径，用于排除检查
        target_abs_path = os.path.abspath(target_dir)
        source_abs_path = os.path.abspath(source_dir)

        # 统计处理的文件数量
        file_count = 0
        skipped_count = 0

        # 打开输出文件准备写入
        with open(output_path, "w", encoding="utf-8") as outfile:
            # 递归遍历源文件夹及其所有子目录
            for dirpath, dirnames, filenames in os.walk(source_abs_path):
                # 检查当前目录是否在目标文件夹中，如果是则跳过
                current_dir_abs = os.path.abspath(dirpath)
                if (
                    os.path.commonprefix([current_dir_abs, target_abs_path])
                    == target_abs_path
                ):
                    skipped_count += len(filenames)
                    continue

                # 处理当前目录中的所有文件
                for filename in filenames:
                    if filename == "o.ahk":
                        continue
                    file_path = os.path.join(dirpath, filename)
                    file_abs_path = os.path.abspath(file_path)

                    # 检查文件是否在目标文件夹中，如果是则跳过
                    if (
                        os.path.commonprefix([file_abs_path, target_abs_path])
                        == target_abs_path
                    ):
                        skipped_count += 1
                        continue

                    # 检查文件是否为指定类型
                    if filename.endswith(f".{file_extension}"):
                        file_count += 1

                        # 计算相对路径，使输出更清晰
                        relative_path = os.path.relpath(file_path, source_abs_path)

                        # 写入当前文件名作为分隔符
                        outfile.write(f"\n; {'='*50}\n")
                        outfile.write(f"; 文件: {filename}\n")
                        outfile.write(f"; 相对路径: {relative_path}\n")
                        outfile.write(f"; 绝对路径: {file_path}\n")
                        outfile.write(f"; {'='*50}\n\n")

                        # 读取并写入文件内容
                        try:
                            with open(file_path, "r", encoding="utf-8") as infile:
                                outfile.write(infile.read())
                                outfile.write("\n\n")  # 在文件内容后添加空行分隔
                        except UnicodeDecodeError:
                            print(
                                f"警告: 无法以UTF-8编码读取文件 {relative_path}，已跳过"
                            )
                        except Exception as e:
                            print(f"处理文件 {relative_path} 时出错: {str(e)}")

        print(f"合并完成！共处理了 {file_count} 个 {file_extension} 文件")
        print(f"跳过了目标文件夹中的 {skipped_count} 个文件")
        print(f"合并后的文件保存至: {output_path}")

    except Exception as e:
        print(f"发生错误: {str(e)}")


# 示例用法
if __name__ == "__main__":
    # 示例：将指定目录及其子目录下所有ahk文件合并到.test文件夹下的merged_files.ahk中
    os.chdir(os.path.expanduser(r"~\Dp1\lazy\nvim1\cmds1"))
    merge_files(
        source_dir="./03-ahk-RadialMouseCommander/",  # 源文件夹路径
        target_dir="./03-ahk-RadialMouseCommander/.test",  # 目标文件夹路径
        file_extension="ahk",  # 要合并的文件类型
        output_filename="merged_files.ahk",  # 合并后的文件名
    )
