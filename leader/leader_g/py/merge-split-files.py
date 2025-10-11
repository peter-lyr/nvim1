import os
import sys
import re
import argparse


def find_split_files(base_file_path):
    directory = os.path.dirname(base_file_path)
    base_filename = os.path.basename(base_file_path)
    pattern = r"(.+)_part\d{3}(\.[^.]+)$"
    match = re.match(pattern, base_filename)
    if not match:
        print(f"错误: 文件 {base_filename} 不符合拆分文件命名模式")
        return None, None, None
    base_name = match.group(1)
    extension = match.group(2)
    split_pattern = re.compile(
        re.escape(base_name) + r"_part\d{3}" + re.escape(extension) + "$"
    )
    split_files = []
    for filename in os.listdir(directory):
        if split_pattern.match(filename):
            split_files.append(os.path.join(directory, filename))

    def extract_number(file_path):
        filename = os.path.basename(file_path)
        num_match = re.search(r"_part(\d{3})", filename)
        return int(num_match.group(1)) if num_match else 0

    split_files.sort(key=extract_number)
    return split_files, base_name, extension


def merge_split_files(split_files, base_name, extension, output_dir=None):
    if not split_files:
        print("没有找到拆分文件")
        return False
    if output_dir is None:
        output_dir = os.path.dirname(split_files[0])
    merged_filename = f"{base_name}_merged{extension}"
    merged_filepath = os.path.join(output_dir, merged_filename)
    print(f"开始合并 {len(split_files)} 个拆分文件...")
    print(f"输出文件: {merged_filepath}")
    try:
        with open(merged_filepath, "wb") as merged_file:
            for i, split_file in enumerate(split_files, 1):
                print(
                    f"正在处理: {os.path.basename(split_file)} ({i}/{len(split_files)})"
                )
                with open(split_file, "rb") as part:
                    data = part.read()
                    merged_file.write(data)
                print(f"  已添加 {len(data)} 字节")
        merged_size = os.path.getsize(merged_filepath)
        total_split_size = sum(os.path.getsize(f) for f in split_files)
        print(f"\n合并完成!")
        print(
            f"合并后文件大小: {merged_size} 字节 ({merged_size / (1024*1024):.2f} MB)"
        )
        print(
            f"拆分文件总大小: {total_split_size} 字节 ({total_split_size / (1024*1024):.2f} MB)"
        )
        if merged_size == total_split_size:
            print("✓ 文件大小验证通过")
        else:
            print("⚠ 文件大小不匹配，可能存在合并问题")
        return True
    except Exception as e:
        print(f"合并过程中出现错误: {e}")
        if os.path.exists(merged_filepath):
            os.remove(merged_filepath)
        return False


def main():
    parser = argparse.ArgumentParser(description="合并拆分的文件")
    parser.add_argument("file", help="任意一个拆分文件（如：filename_part001.ext）")
    parser.add_argument("-o", "--output", help="输出目录（默认为拆分文件所在目录）")
    if len(sys.argv) > 1:
        args = parser.parse_args()
        split_file_path = args.file
        output_dir = args.output
    else:
        if len(sys.argv) == 1:
            print("请将拆分文件拖放到此脚本上，或通过命令行参数指定文件。")
            input("按回车键退出...")
            return
        split_file_path = sys.argv[1]
        output_dir = None
    if not os.path.isfile(split_file_path):
        print(f"错误: 文件不存在: {split_file_path}")
        input("按回车键退出...")
        return
    print(f"输入文件: {split_file_path}")
    split_files, base_name, extension = find_split_files(split_file_path)
    if split_files is None:
        input("按回车键退出...")
        return
    if not split_files:
        print("未找到相关的拆分文件")
        input("按回车键退出...")
        return
    print(f"找到 {len(split_files)} 个拆分文件:")
    for f in split_files:
        file_size = os.path.getsize(f)
        print(f"  {os.path.basename(f)} ({file_size} 字节)")
    success = merge_split_files(split_files, base_name, extension, output_dir)
    if success:
        print(f"\n合并成功！文件已保存为: {base_name}_merged{extension}")
    else:
        print("\n合并失败！")
    input("按回车键退出...")


if __name__ == "__main__":
    main()

