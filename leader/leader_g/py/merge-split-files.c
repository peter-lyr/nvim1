#include <ctype.h>
#include <dirent.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <direct.h>
#include <windows.h>
#define mkdir(path, mode) _mkdir(path)
#define SEPARATOR "\\"
#else
#include <sys/types.h>
#include <unistd.h>
#define SEPARATOR "/"
#endif

#define MAX_PATH_LENGTH 1024
#define MAX_FILES 1000
#define BUFFER_SIZE 8192

typedef struct {
  char path[MAX_PATH_LENGTH];
  int part_number;
} SplitFile;

typedef struct {
  SplitFile files[MAX_FILES];
  int count;
  char base_name[256];
  char extension[64];
} FileCollection;

// 提取文件名中的部分编号
int extract_part_number(const char *filename) {
  const char *part_str = strstr(filename, "_part");
  if (!part_str)
    return -1;

  part_str += 5; // 跳过 "_part"

  // 检查接下来的3个字符是否都是数字
  if (!isdigit(part_str[0]) || !isdigit(part_str[1]) || !isdigit(part_str[2])) {
    return -1;
  }

  return (part_str[0] - '0') * 100 + (part_str[1] - '0') * 10 +
         (part_str[2] - '0');
}

// 比较函数用于排序
int compare_files(const void *a, const void *b) {
  const SplitFile *fileA = (const SplitFile *)a;
  const SplitFile *fileB = (const SplitFile *)b;
  return fileA->part_number - fileB->part_number;
}

// 查找所有拆分文件
int find_split_files(const char *base_file_path, FileCollection *collection) {
  char directory[MAX_PATH_LENGTH];
  char base_filename[256];
  char temp_path[MAX_PATH_LENGTH];

  // 提取目录和文件名
  strcpy(temp_path, base_file_path);

  char *last_slash = strrchr(temp_path, SEPARATOR[0]);
  if (last_slash) {
    *last_slash = '\0';
    strcpy(directory, temp_path);
    strcpy(base_filename, last_slash + 1);
  } else {
    strcpy(directory, ".");
    strcpy(base_filename, temp_path);
  }

  // 解析基础文件名和扩展名
  const char *part_pos = strstr(base_filename, "_part");
  if (!part_pos) {
    printf("错误: 文件 %s 不符合拆分文件命名模式\n", base_filename);
    return 0;
  }

  int base_name_len = part_pos - base_filename;
  strncpy(collection->base_name, base_filename, base_name_len);
  collection->base_name[base_name_len] = '\0';

  const char *ext_pos = strchr(part_pos, '.');
  if (ext_pos) {
    strcpy(collection->extension, ext_pos);
  } else {
    strcpy(collection->extension, "");
  }

  // 查找目录中的文件
  DIR *dirp = opendir(directory);
  if (!dirp) {
    printf("错误: 无法打开目录 %s\n", directory);
    return 0;
  }

  struct dirent *entry;
  collection->count = 0;

  while ((entry = readdir(dirp)) != NULL && collection->count < MAX_FILES) {
    // 检查文件名是否匹配模式
    if (strstr(entry->d_name, collection->base_name) &&
        strstr(entry->d_name, "_part") &&
        strstr(entry->d_name, collection->extension)) {

      int part_num = extract_part_number(entry->d_name);
      if (part_num != -1) {
        // 构建完整路径
        snprintf(collection->files[collection->count].path, MAX_PATH_LENGTH,
                 "%s%s%s", directory, SEPARATOR, entry->d_name);
        collection->files[collection->count].part_number = part_num;
        collection->count++;
      }
    }
  }

  closedir(dirp);

  if (collection->count == 0) {
    printf("未找到相关的拆分文件\n");
    return 0;
  }

  // 按部分编号排序
  qsort(collection->files, collection->count, sizeof(SplitFile), compare_files);

  return 1;
}

// 合并拆分文件
int merge_split_files(const FileCollection *collection,
                      const char *output_dir) {
  if (collection->count == 0) {
    printf("没有找到拆分文件\n");
    return 0;
  }

  char output_path[MAX_PATH_LENGTH];
  if (output_dir && strlen(output_dir) > 0) {
    strcpy(output_path, output_dir);
    // 如果输出目录不存在则创建
    mkdir(output_path, 0755);
  } else {
    // 提取第一个文件的目录
    strcpy(output_path, collection->files[0].path);
    char *last_slash = strrchr(output_path, SEPARATOR[0]);
    if (last_slash) {
      *last_slash = '\0';
    }
  }

  // 构建输出文件路径
  snprintf(output_path + strlen(output_path),
           MAX_PATH_LENGTH - strlen(output_path), "%s%s_merged%s", SEPARATOR,
           collection->base_name, collection->extension);

  printf("开始合并 %d 个拆分文件...\n", collection->count);
  printf("输出文件: %s\n", output_path);

  FILE *output_file = fopen(output_path, "wb");
  if (!output_file) {
    printf("错误: 无法创建输出文件 %s\n", output_path);
    return 0;
  }

  unsigned long total_size = 0;
  int success = 1;

  for (int i = 0; i < collection->count; i++) {
    const char *filename = strrchr(collection->files[i].path, SEPARATOR[0]);
    if (filename)
      filename++;
    else
      filename = collection->files[i].path;

    printf("正在处理: %s (%d/%d)\n", filename, i + 1, collection->count);

    FILE *input_file = fopen(collection->files[i].path, "rb");
    if (!input_file) {
      printf("  错误: 无法打开文件 %s\n", collection->files[i].path);
      success = 0;
      break;
    }

    // 获取文件大小
    fseek(input_file, 0, SEEK_END);
    long file_size = ftell(input_file);
    fseek(input_file, 0, SEEK_SET);

    // 读取并写入文件
    char buffer[BUFFER_SIZE];
    size_t bytes_read;
    unsigned long bytes_written = 0;

    while ((bytes_read = fread(buffer, 1, BUFFER_SIZE, input_file)) > 0) {
      size_t bytes_written_this_time =
          fwrite(buffer, 1, bytes_read, output_file);
      if (bytes_written_this_time != bytes_read) {
        printf("  错误: 写入文件时发生错误\n");
        success = 0;
        break;
      }
      bytes_written += bytes_written_this_time;
    }

    printf("  已添加 %lu 字节\n", bytes_written);
    total_size += bytes_written;

    fclose(input_file);

    if (!success) {
      break;
    }
  }

  fclose(output_file);

  if (!success) {
    remove(output_path); // 删除不完整的输出文件
    return 0;
  }

  // 验证文件大小
  struct stat st;
  if (stat(output_path, &st) == 0) {
    unsigned long merged_size = st.st_size;
    printf("\n合并完成!\n");
    printf("合并后文件大小: %lu 字节 (%.2f MB)\n", merged_size,
           merged_size / (1024.0 * 1024.0));
    printf("拆分文件总大小: %lu 字节 (%.2f MB)\n", total_size,
           total_size / (1024.0 * 1024.0));

    if (merged_size == total_size) {
      printf("✓ 文件大小验证通过\n");
    } else {
      printf("⚠ 文件大小不匹配，可能存在合并问题\n");
    }
  }

  return 1;
}

// 显示用法信息
void print_usage(const char *program_name) {
  printf("用法: %s <拆分文件> [-o 输出目录]\n", program_name);
  printf("示例: %s document_part001.txt\n", program_name);
  printf("       %s document_part001.txt -o C:\\output\n", program_name);
}

int main(int argc, char *argv[]) {
// 设置控制台输出编码为UTF-8
#ifdef _WIN32
  SetConsoleOutputCP(65001);
#endif

  setlocale(LC_ALL, "zh_CN.UTF-8");

  if (argc < 2) {
    printf("请将拆分文件拖放到此程序上，或通过命令行参数指定文件。\n");
    print_usage("merge_split_files.exe");
    printf("按回车键退出...");
    getchar();
    return 1;
  }

  char *input_file = NULL;
  char *output_dir = NULL;

  // 解析命令行参数
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      output_dir = argv[i + 1];
      i++;
    } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
      print_usage("merge_split_files.exe");
      return 0;
    } else {
      input_file = argv[i];
    }
  }

  if (!input_file) {
    printf("错误: 未指定输入文件\n");
    print_usage("merge_split_files.exe");
    return 1;
  }

  // 检查文件是否存在
  FILE *test_file = fopen(input_file, "rb");
  if (!test_file) {
    printf("错误: 文件不存在: %s\n", input_file);
    printf("按回车键退出...");
    getchar();
    return 1;
  }
  fclose(test_file);

  printf("输入文件: %s\n", input_file);

  FileCollection collection;
  if (!find_split_files(input_file, &collection)) {
    printf("按回车键退出...");
    getchar();
    return 1;
  }

  printf("找到 %d 个拆分文件:\n", collection.count);
  for (int i = 0; i < collection.count; i++) {
    struct stat st;
    if (stat(collection.files[i].path, &st) == 0) {
      const char *filename = strrchr(collection.files[i].path, SEPARATOR[0]);
      if (filename)
        filename++;
      else
        filename = collection.files[i].path;

      printf("  %s (%ld 字节)\n", filename, st.st_size);
    } else {
      const char *filename = strrchr(collection.files[i].path, SEPARATOR[0]);
      if (filename)
        filename++;
      else
        filename = collection.files[i].path;

      printf("  %s (无法获取大小)\n", filename);
    }
  }

  int success = merge_split_files(&collection, output_dir);

  if (success) {
    printf("\n合并成功！\n");
  } else {
    printf("\n合并失败！\n");
  }

  printf("按回车键退出...");
  getchar();

  return success ? 0 : 1;
}
