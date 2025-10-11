#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <windows.h>

// 使用系统定义的 MAX_PATH，或者定义我们自己的常量
#ifndef MAX_PATH
#define MAX_PATH 4096
#else
// 如果系统 MAX_PATH 太小，我们可以定义一个新的常量
#define OUR_MAX_PATH 4096
#endif

// 如果没有定义 OUR_MAX_PATH，就使用 MAX_PATH
#ifndef OUR_MAX_PATH
#define OUR_MAX_PATH MAX_PATH
#endif

#define MAX_CMD 8192
#define CHUNK_SIZE (50 * 1024 * 1024)
#define MAX_RETRIES 3

// 函数声明
int run_git_command(const char *cmd, int max_retries);
int check_network_connection();
char *get_git_root();
char **get_unstaged_files(int *file_count);
int is_file_already_split(const char *file_path);
void mark_file_as_split(const char *file_path);
void add_to_gitignore(const char *file_path);
int copy_merge_exe_to_directory(const char *target_dir);
int split_large_file(const char *file_path, long chunk_size);
char **process_large_files(const char *git_root, int *chunk_count);
long get_file_size(const char *file_path);
int check_remote_connection();
int batch_commit_files(const char *commit_msg_file, const char *git_root);
char **split_string(const char *str, const char *delim, int *count);
void free_string_array(char **array, int count);

// 运行Git命令并支持重试
int run_git_command(const char *cmd, int max_retries) {
  printf("执行命令: %s\n", cmd);
  int result = 1;

  for (int attempt = 0; attempt < max_retries; attempt++) {
    result = system(cmd);
    if (result == 0) {
      return result;
    } else {
      printf("命令执行失败 (尝试 %d/%d): %s\n", attempt + 1, max_retries, cmd);
      if (attempt < max_retries - 1) {
        int wait_time = 5 * (attempt + 1);
        printf("等待 %d 秒后重试...\n", wait_time);
        Sleep(wait_time * 1000); // Windows 使用 Sleep，单位是毫秒
      }
    }
  }
  return result;
}

// 检查网络连接
int check_network_connection() {
#ifdef _WIN32
  return system("ping -n 1 github.com > nul") == 0;
#else
  return system("ping -c 1 github.com > /dev/null 2>&1") == 0;
#endif
}

// 获取Git根目录
char *get_git_root() {
  FILE *fp = popen("git rev-parse --show-toplevel", "r");
  if (fp == NULL) {
    printf("错误: 无法执行git命令\n");
    return NULL;
  }

  char buffer[OUR_MAX_PATH];
  if (fgets(buffer, sizeof(buffer), fp) == NULL) {
    pclose(fp);
    printf("错误: 当前目录不是git仓库\n");
    return NULL;
  }

  pclose(fp);

  // 去除换行符
  buffer[strcspn(buffer, "\n")] = 0;
  return strdup(buffer);
}

// 获取未暂存的文件列表
char **get_unstaged_files(int *file_count) {
  FILE *fp = popen("git status --porcelain -uall", "r");
  if (fp == NULL) {
    *file_count = 0;
    return NULL;
  }

  char buffer[OUR_MAX_PATH];
  char **files = NULL;
  int count = 0;
  int capacity = 10;

  files = (char **)malloc(capacity * sizeof(char *));

  while (fgets(buffer, sizeof(buffer), fp) != NULL) {
    // 去除换行符
    buffer[strcspn(buffer, "\n")] = 0;

    if (strlen(buffer) >= 3) {
      // 跳过状态标记，获取文件名
      const char *filename = buffer + 3;

      if (count >= capacity) {
        capacity *= 2;
        files = (char **)realloc(files, capacity * sizeof(char *));
      }

      files[count] = strdup(filename);
      count++;
    }
  }

  pclose(fp);
  *file_count = count;
  return files;
}

// 检查文件是否已经被拆分
int is_file_already_split(const char *file_path) {
  char marker_path[OUR_MAX_PATH];
  const char *file_name = strrchr(file_path, '/');
  if (file_name == NULL) {
    file_name = strrchr(file_path, '\\');
    if (file_name == NULL) {
      file_name = file_path;
    } else {
      file_name++;
    }
  } else {
    file_name++;
  }

  const char *dir_path = file_path;
  char *last_slash = strrchr(file_path, '/');
  if (last_slash == NULL) {
    last_slash = strrchr(file_path, '\\');
  }

  if (last_slash != NULL) {
    int dir_len = last_slash - file_path;
    strncpy(marker_path, file_path, dir_len);
    marker_path[dir_len] = '\0';
#ifdef _WIN32
    snprintf(marker_path + dir_len, sizeof(marker_path) - dir_len,
             "\\.%s.split", file_name);
#else
    snprintf(marker_path + dir_len, sizeof(marker_path) - dir_len, "/.%s.split",
             file_name);
#endif
  } else {
#ifdef _WIN32
    snprintf(marker_path, sizeof(marker_path), ".%s.split", file_name);
#else
    snprintf(marker_path, sizeof(marker_path), ".%s.split", file_name);
#endif
  }

  struct stat st;
  return stat(marker_path, &st) == 0;
}

// 标记文件为已拆分
void mark_file_as_split(const char *file_path) {
  char marker_path[OUR_MAX_PATH];
  const char *file_name = strrchr(file_path, '/');
  if (file_name == NULL) {
    file_name = strrchr(file_path, '\\');
    if (file_name == NULL) {
      file_name = file_path;
    } else {
      file_name++;
    }
  } else {
    file_name++;
  }

  const char *dir_path = file_path;
  char *last_slash = strrchr(file_path, '/');
  if (last_slash == NULL) {
    last_slash = strrchr(file_path, '\\');
  }

  if (last_slash != NULL) {
    int dir_len = last_slash - file_path;
    strncpy(marker_path, file_path, dir_len);
    marker_path[dir_len] = '\0';
#ifdef _WIN32
    snprintf(marker_path + dir_len, sizeof(marker_path) - dir_len,
             "\\.%s.split", file_name);
#else
    snprintf(marker_path + dir_len, sizeof(marker_path) - dir_len, "/.%s.split",
             file_name);
#endif
  } else {
#ifdef _WIN32
    snprintf(marker_path, sizeof(marker_path), ".%s.split", file_name);
#else
    snprintf(marker_path, sizeof(marker_path), ".%s.split", file_name);
#endif
  }

  FILE *f = fopen(marker_path, "wb");
  if (f != NULL) {
    fclose(f);
  }
}

// 添加到.gitignore
void add_to_gitignore(const char *file_path) {
  char gitignore_path[OUR_MAX_PATH];
  const char *file_name = strrchr(file_path, '/');
  if (file_name == NULL) {
    file_name = strrchr(file_path, '\\');
    if (file_name == NULL) {
      file_name = file_path;
    } else {
      file_name++;
    }
  } else {
    file_name++;
  }

  // 提取文件名和扩展名
  char file_base[OUR_MAX_PATH];
  char file_ext[OUR_MAX_PATH];
  const char *dot = strrchr(file_name, '.');

  if (dot != NULL) {
    int base_len = dot - file_name;
    strncpy(file_base, file_name, base_len);
    file_base[base_len] = '\0';
    strcpy(file_ext, dot);
  } else {
    strcpy(file_base, file_name);
    strcpy(file_ext, "");
  }

  const char *dir_path = file_path;
  char *last_slash = strrchr(file_path, '/');
  if (last_slash == NULL) {
    last_slash = strrchr(file_path, '\\');
  }

  if (last_slash != NULL) {
    int dir_len = last_slash - file_path;
    strncpy(gitignore_path, file_path, dir_len);
    gitignore_path[dir_len] = '\0';
#ifdef _WIN32
    strcat(gitignore_path, "\\.gitignore");
#else
    strcat(gitignore_path, "/.gitignore");
#endif
  } else {
#ifdef _WIN32
    strcpy(gitignore_path, ".gitignore");
#else
    strcpy(gitignore_path, ".gitignore");
#endif
  }

  // 构建要添加的文件名
  char original_file[OUR_MAX_PATH];
  char merged_file[OUR_MAX_PATH];

  strcpy(original_file, file_name);
  snprintf(merged_file, sizeof(merged_file), "%s-merged%s", file_base,
           file_ext);

  // 读取现有的.gitignore内容
  FILE *f = fopen(gitignore_path, "r");
  char existing_content[65536] = "";

  if (f != NULL) {
    size_t len = fread(existing_content, 1, sizeof(existing_content) - 1, f);
    existing_content[len] = '\0';
    fclose(f);
  }

  // 检查是否已经存在
  int original_exists = (strstr(existing_content, original_file) != NULL);
  int merged_exists = (strstr(existing_content, merged_file) != NULL);

  // 添加不存在的条目
  f = fopen(gitignore_path, "a");
  if (f != NULL) {
    if (!original_exists) {
      fprintf(f, "%s\n", original_file);
      printf("已将 %s 添加到 %s\n", original_file, gitignore_path);
    }
    if (!merged_exists) {
      fprintf(f, "%s\n", merged_file);
      printf("已将 %s 添加到 %s\n", merged_file, gitignore_path);
    }
    fclose(f);
  }
}

// 复制合并工具到目录
int copy_merge_exe_to_directory(const char *target_dir) {
  char exe_source_path[OUR_MAX_PATH];
  char exe_target_path[OUR_MAX_PATH];

// 获取当前可执行文件路径
#ifdef _WIN32
  GetModuleFileName(NULL, exe_source_path, OUR_MAX_PATH);
#else
  ssize_t len = readlink("/proc/self/exe", exe_source_path, OUR_MAX_PATH - 1);
  if (len != -1) {
    exe_source_path[len] = '\0';
  } else {
    strcpy(exe_source_path, "merge_split_file");
  }
#endif

  // 构建源路径和目标路径
  char *last_slash = strrchr(exe_source_path, '/');
  if (last_slash == NULL) {
    last_slash = strrchr(exe_source_path, '\\');
  }

  if (last_slash != NULL) {
    int dir_len = last_slash - exe_source_path;
#ifdef _WIN32
    strncpy(exe_source_path + dir_len + 1, "merge_split_file.exe",
            OUR_MAX_PATH - dir_len - 1);
#else
    strncpy(exe_source_path + dir_len + 1, "merge_split_file",
            OUR_MAX_PATH - dir_len - 1);
#endif
  } else {
#ifdef _WIN32
    strcpy(exe_source_path, "merge_split_file.exe");
#else
    strcpy(exe_source_path, "merge_split_file");
#endif
  }

#ifdef _WIN32
  snprintf(exe_target_path, sizeof(exe_target_path), "%s\\merge_split_file.exe",
           target_dir);
#else
  snprintf(exe_target_path, sizeof(exe_target_path), "%s/merge_split_file",
           target_dir);
#endif

  // 检查源文件是否存在
  struct stat st;
  if (stat(exe_source_path, &st) != 0) {
    printf("警告: merge_split_file 不存在于 %s\n", exe_source_path);
    return 0;
  }

  // 复制文件
  FILE *source = fopen(exe_source_path, "rb");
  if (source == NULL) {
    printf("复制 merge_split_file 失败: 无法打开源文件\n");
    return 0;
  }

  FILE *target = fopen(exe_target_path, "wb");
  if (target == NULL) {
    fclose(source);
    printf("复制 merge_split_file 失败: 无法创建目标文件\n");
    return 0;
  }

  char buffer[8192];
  size_t bytes;
  while ((bytes = fread(buffer, 1, sizeof(buffer), source)) > 0) {
    fwrite(buffer, 1, bytes, target);
  }

  fclose(source);
  fclose(target);

// 设置执行权限（Unix系统）
#ifndef _WIN32
  chmod(exe_target_path, 0755);
#endif

  printf("已复制 merge_split_file 到 %s\n", target_dir);
  return 1;
}

// 拆分大文件
int split_large_file(const char *file_path, long chunk_size) {
  printf("开始拆分大文件: %s\n", file_path);

  struct stat st;
  if (stat(file_path, &st) != 0) {
    printf("错误: 无法访问文件 %s\n", file_path);
    return 0;
  }

  long file_size = st.st_size;
  int num_chunks = (file_size + chunk_size - 1) / chunk_size;

  // 提取文件名和扩展名
  const char *file_name = strrchr(file_path, '/');
  if (file_name == NULL) {
    file_name = strrchr(file_path, '\\');
    if (file_name == NULL) {
      file_name = file_path;
    } else {
      file_name++;
    }
  } else {
    file_name++;
  }

  char file_base[OUR_MAX_PATH];
  char file_ext[OUR_MAX_PATH];
  const char *dot = strrchr(file_name, '.');

  if (dot != NULL) {
    int base_len = dot - file_name;
    strncpy(file_base, file_name, base_len);
    file_base[base_len] = '\0';
    strcpy(file_ext, dot);
  } else {
    strcpy(file_base, file_name);
    strcpy(file_ext, "");
  }

  // 获取目录路径
  char dir_path[OUR_MAX_PATH];
  const char *last_slash = strrchr(file_path, '/');
  if (last_slash == NULL) {
    last_slash = strrchr(file_path, '\\');
  }

  if (last_slash != NULL) {
    int dir_len = last_slash - file_path;
    strncpy(dir_path, file_path, dir_len);
    dir_path[dir_len] = '\0';
  } else {
    strcpy(dir_path, ".");
  }

  FILE *original_file = fopen(file_path, "rb");
  if (original_file == NULL) {
    printf("错误: 无法打开文件 %s\n", file_path);
    return 0;
  }

  int success = 1;
  for (int i = 0; i < num_chunks; i++) {
    char chunk_file_name[OUR_MAX_PATH];
    char chunk_file_path[OUR_MAX_PATH];

    snprintf(chunk_file_name, sizeof(chunk_file_name), "%s_part%03d%s",
             file_base, i + 1, file_ext);
#ifdef _WIN32
    snprintf(chunk_file_path, sizeof(chunk_file_path), "%s\\%s", dir_path,
             chunk_file_name);
#else
    snprintf(chunk_file_path, sizeof(chunk_file_path), "%s/%s", dir_path,
             chunk_file_name);
#endif

    FILE *chunk_file = fopen(chunk_file_path, "wb");
    if (chunk_file == NULL) {
      printf("错误: 无法创建分块文件 %s\n", chunk_file_path);
      success = 0;
      break;
    }

    char *buffer = (char *)malloc(chunk_size);
    if (buffer == NULL) {
      printf("错误: 内存分配失败\n");
      fclose(chunk_file);
      success = 0;
      break;
    }

    size_t bytes_read = fread(buffer, 1, chunk_size, original_file);
    if (bytes_read > 0) {
      size_t bytes_written = fwrite(buffer, 1, bytes_read, chunk_file);
      if (bytes_written != bytes_read) {
        printf("错误: 写入分块文件失败 %s\n", chunk_file_path);
        free(buffer);
        fclose(chunk_file);
        success = 0;
        break;
      }
      printf("创建分块文件: %s (%zu bytes)\n", chunk_file_path, bytes_read);
    }

    free(buffer);
    fclose(chunk_file);
  }

  fclose(original_file);

  if (success) {
    mark_file_as_split(file_path);
    copy_merge_exe_to_directory(dir_path);
  }

  return success;
}

// 处理大文件
char **process_large_files(const char *git_root, int *chunk_count) {
  int unstaged_count;
  char **unstaged_files = get_unstaged_files(&unstaged_count);

  char **large_files = NULL;
  char **all_chunks = NULL;
  int large_count = 0;
  int chunks_total = 0;
  int large_capacity = 10;
  int chunks_capacity = 100;

  large_files = (char **)malloc(large_capacity * sizeof(char *));
  all_chunks = (char **)malloc(chunks_capacity * sizeof(char *));

  for (int i = 0; i < unstaged_count; i++) {
    char file_path[OUR_MAX_PATH];
#ifdef _WIN32
    snprintf(file_path, sizeof(file_path), "%s\\%s", git_root,
             unstaged_files[i]);
#else
    snprintf(file_path, sizeof(file_path), "%s/%s", git_root,
             unstaged_files[i]);
#endif

    struct stat st;
    if (stat(file_path, &st) == 0 && S_ISREG(st.st_mode)) {
      long file_size = st.st_size;
      if (file_size > 50 * 1024 * 1024) {
        if (!is_file_already_split(file_path)) {
          if (large_count >= large_capacity) {
            large_capacity *= 2;
            large_files =
                (char **)realloc(large_files, large_capacity * sizeof(char *));
          }
          large_files[large_count] = strdup(file_path);
          large_count++;
        } else {
          printf("文件 %s 已经被拆分过，跳过\n", unstaged_files[i]);
        }
      }
    }
  }

  for (int i = 0; i < large_count; i++) {
    if (split_large_file(large_files[i], CHUNK_SIZE)) {
      // 这里简化处理，实际应该获取拆分后的文件列表
      add_to_gitignore(large_files[i]);
    }
    free(large_files[i]);
  }

  free(large_files);
  free_string_array(unstaged_files, unstaged_count);

  *chunk_count = chunks_total;
  return all_chunks;
}

// 获取文件大小
long get_file_size(const char *file_path) {
  struct stat st;
  if (stat(file_path, &st) == 0 && S_ISREG(st.st_mode)) {
    return st.st_size;
  }
  return 0;
}

// 检查远程连接
int check_remote_connection() {
  printf("检查远程仓库连接...\n");

  FILE *fp = popen("git config --get remote.origin.url", "r");
  if (fp == NULL) {
    printf("错误: 无法执行git命令\n");
    return 0;
  }

  char buffer[OUR_MAX_PATH];
  if (fgets(buffer, sizeof(buffer), fp) == NULL) {
    pclose(fp);
    printf("错误: 未配置远程仓库 origin\n");
    return 0;
  }
  pclose(fp);

  for (int i = 0; i < 2; i++) {
    if (check_network_connection()) {
      printf("远程仓库连接正常\n");
      return 1;
    }
    printf("网络连接检查失败，等待 3 秒后重试... (%d/2)\n", i + 1);
#ifdef _WIN32
    Sleep(3000);
#else
    sleep(3);
#endif
  }

  printf("警告: 网络连接可能有问题，但仍将继续尝试提交\n");
  return 1;
}

// 字符串分割函数
char **split_string(const char *str, const char *delim, int *count) {
  if (str == NULL || strlen(str) == 0) {
    *count = 0;
    return NULL;
  }

  // 复制字符串以便修改
  char *str_copy = strdup(str);
  char **result = NULL;
  int capacity = 10;
  int num = 0;

  result = (char **)malloc(capacity * sizeof(char *));

  char *token = strtok(str_copy, delim);
  while (token != NULL) {
    if (num >= capacity) {
      capacity *= 2;
      result = (char **)realloc(result, capacity * sizeof(char *));
    }

    result[num] = strdup(token);
    num++;

    token = strtok(NULL, delim);
  }

  free(str_copy);
  *count = num;
  return result;
}

// 释放字符串数组
void free_string_array(char **array, int count) {
  if (array == NULL)
    return;

  for (int i = 0; i < count; i++) {
    free(array[i]);
  }
  free(array);
}

// 分批提交文件
int batch_commit_files(const char *commit_msg_file, const char *git_root) {
  FILE *fp = popen("git status --porcelain -uall", "r");
  if (fp == NULL) {
    printf("错误: 无法获取git状态\n");
    return 0;
  }

  char buffer[OUR_MAX_PATH];
  char **all_files = NULL;
  long *file_sizes = NULL;
  int file_count = 0;
  int capacity = 100;

  all_files = (char **)malloc(capacity * sizeof(char *));
  file_sizes = (long *)malloc(capacity * sizeof(long));

  while (fgets(buffer, sizeof(buffer), fp) != NULL) {
    buffer[strcspn(buffer, "\n")] = 0;

    if (strlen(buffer) >= 2) {
      char status[3] = {buffer[0], buffer[1], '\0'};
      const char *filename = buffer + 3;

      char file_path[OUR_MAX_PATH];
#ifdef _WIN32
      snprintf(file_path, sizeof(file_path), "%s\\%s", git_root, filename);
#else
      snprintf(file_path, sizeof(file_path), "%s/%s", git_root, filename);
#endif

      if (strcmp(status, "??") == 0 || strcmp(status, "?") == 0 ||
          status[0] == 'M' || status[0] == 'A' ||
          (status[0] == ' ' && status[1] == 'M') || strcmp(status, "AM") == 0 ||
          strcmp(status, "MM") == 0) {

        if (file_count >= capacity) {
          capacity *= 2;
          all_files = (char **)realloc(all_files, capacity * sizeof(char *));
          file_sizes = (long *)realloc(file_sizes, capacity * sizeof(long));
        }

        all_files[file_count] = strdup(filename);
        file_sizes[file_count] = get_file_size(file_path);
        file_count++;

      } else if (status[0] == 'D' || (status[0] == ' ' && status[1] == 'D')) {
        // 处理删除操作
        char cmd[MAX_CMD];
        snprintf(cmd, sizeof(cmd), "git rm \"%s\"", filename);
        run_git_command(cmd, 1);
      }
    }
  }
  pclose(fp);

  if (file_count == 0) {
    // 检查是否有已暂存的删除操作
    FILE *staged_fp = popen("git diff --name-only --cached", "r");
    if (staged_fp != NULL) {
      int has_staged = 0;
      while (fgets(buffer, sizeof(buffer), staged_fp) != NULL) {
        if (strlen(buffer) > 1) {
          has_staged = 1;
          break;
        }
      }
      pclose(staged_fp);

      if (has_staged) {
        printf("检测到已暂存的删除操作，将继续提交\n");
        char commit_cmd[MAX_CMD];
        snprintf(commit_cmd, sizeof(commit_cmd), "git commit -F \"%s\"",
                 commit_msg_file);
        int commit_result = run_git_command(commit_cmd, 1);
        if (commit_result != 0) {
          printf("提交失败\n");
          free(all_files);
          free(file_sizes);
          return 0;
        }

        int push_result = run_git_command("git push", 5);
        if (push_result != 0) {
          printf("推送失败\n");
          free(all_files);
          free(file_sizes);
          return 0;
        }

        printf("删除操作提交并推送成功\n");
        free(all_files);
        free(file_sizes);
        return 1;
      } else {
        printf("没有检测到需要提交的文件变更\n");
        free(all_files);
        free(file_sizes);
        return 1;
      }
    }
  }

  // 分批处理
  long max_batch_size = 100 * 1024 * 1024; // 100MB
  int batch_count = 0;
  int current_batch_start = 0;
  long current_batch_size = 0;

  for (int i = 0; i < file_count; i++) {
    if (file_sizes[i] > max_batch_size) {
      printf("警告: 文件 %s 大小 %.2fM 超过单次提交限制\n", all_files[i],
             file_sizes[i] / (1024.0 * 1024.0));
      continue;
    }

    if (current_batch_size + file_sizes[i] > max_batch_size) {
      // 提交当前批次
      batch_count++;
      printf("\n提交批次 %d，包含 %d 个文件，总大小 %.2fM\n", batch_count,
             i - current_batch_start, current_batch_size / (1024.0 * 1024.0));

      for (int j = current_batch_start; j < i; j++) {
        char add_cmd[MAX_CMD];
        snprintf(add_cmd, sizeof(add_cmd), "git add \"%s\"", all_files[j]);
        run_git_command(add_cmd, 1);
      }

      char commit_cmd[MAX_CMD];
      snprintf(commit_cmd, sizeof(commit_cmd), "git commit -F \"%s\"",
               commit_msg_file);
      int commit_result = run_git_command(commit_cmd, 1);
      if (commit_result != 0) {
        printf("提交批次 %d 失败\n", batch_count);
        free(all_files);
        free(file_sizes);
        return 0;
      }

      int push_result = run_git_command("git push", 5);
      if (push_result != 0) {
        printf("推送批次 %d 失败\n", batch_count);
        free(all_files);
        free(file_sizes);
        return 0;
      }

      printf("批次 %d 提交并推送成功\n", batch_count);

      current_batch_start = i;
      current_batch_size = file_sizes[i];
    } else {
      current_batch_size += file_sizes[i];
    }
  }

  // 提交最后一批
  if (current_batch_start < file_count) {
    batch_count++;
    printf("\n提交批次 %d，包含 %d 个文件，总大小 %.2fM\n", batch_count,
           file_count - current_batch_start,
           current_batch_size / (1024.0 * 1024.0));

    for (int j = current_batch_start; j < file_count; j++) {
      char add_cmd[MAX_CMD];
      snprintf(add_cmd, sizeof(add_cmd), "git add \"%s\"", all_files[j]);
      run_git_command(add_cmd, 1);
    }

    char commit_cmd[MAX_CMD];
    snprintf(commit_cmd, sizeof(commit_cmd), "git commit -F \"%s\"",
             commit_msg_file);
    int commit_result = run_git_command(commit_cmd, 1);
    if (commit_result != 0) {
      printf("提交批次 %d 失败\n", batch_count);
      free(all_files);
      free(file_sizes);
      return 0;
    }

    int push_result = run_git_command("git push", 5);
    if (push_result != 0) {
      printf("推送批次 %d 失败\n", batch_count);
      free(all_files);
      free(file_sizes);
      return 0;
    }

    printf("批次 %d 提交并推送成功\n", batch_count);
  }

  // 清理内存
  for (int i = 0; i < file_count; i++) {
    free(all_files[i]);
  }
  free(all_files);
  free(file_sizes);

  return 1;
}

// 主函数
int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("用法: %s <commit_message_file>\n", argv[0]);
    return 1;
  }

  const char *commit_msg_file = argv[1];

  struct stat st;
  if (stat(commit_msg_file, &st) != 0) {
    printf("错误: 提交信息文件不存在: %s\n", commit_msg_file);
    return 1;
  }

  char *git_root = get_git_root();
  if (git_root == NULL) {
    return 1;
  }

  printf("Git仓库根目录: %s\n", git_root);

  if (chdir(git_root) != 0) {
    printf("错误: 无法切换到仓库目录\n");
    free(git_root);
    return 1;
  }

  printf("检查大文件...\n");
  int chunk_count;
  char **chunk_files = process_large_files(git_root, &chunk_count);

  if (chunk_count > 0) {
    printf("拆分了 %d 个大文件\n", chunk_count);
    free_string_array(chunk_files, chunk_count);
  }

  printf("开始分批提交...\n");
  int success = batch_commit_files(commit_msg_file, git_root);

  free(git_root);

  if (success) {
    printf("\n所有操作完成!\n");
    return 0;
  } else {
    printf("\n操作过程中出现错误!\n");
    return 1;
  }
}
