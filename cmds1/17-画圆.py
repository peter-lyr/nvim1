# python用pynput时时刻刻监测鼠标，当鼠标右键按下时，用tkinter库以按下的位置为圆心画一个圆圈，当鼠标右键松开时关掉该圆圈
# 按住右键当移动到圆圈外后，在鼠标上方实时显示相对于圆心的位置，共8个：上，下，左，右，右上，右下，左下，左上，松开右键后结束显示
# 按住右键且鼠标保持在圆圈内时，监测鼠标左键，中键和滚轮的状态，分别用3个变量表示，默认值为0，检测到有动作时分别加1，当它们有不为0时，实时在鼠标上方显示出来它们的值，这3个变量当分别加到6,4,5时，不再往上加而变为0
# 圆圈换成实心圆，鼠标不可穿透
# 实心圆只有在右键移动到20个像素以外时，或者当右键按下超过2秒时，才去画
# 画圆之后把圆窗口激活
# 改为按下右键后就画圆

# 解决缩放非100%屏幕圆心位置不对的问题
# 圆圈半径30像素改成50
# fix: 如果有两块或多个屏幕，那只有一个屏幕上可以画圆，其他屏幕上画不了圆了
# 支持多显示器环境

import tkinter as tk
from pynput import mouse
import threading
from queue import Queue
import math
import ctypes
import time


class MouseCircleDrawer:
    def __init__(self):
        # 获取DPI缩放比例
        self.scale_factor = self.get_scale_factor()

        # 创建消息队列用于线程间通信
        self.queue = Queue()

        # 创建主窗口
        self.root = tk.Tk()
        self.root.overrideredirect(True)  # 无边框窗口
        self.root.attributes("-alpha", 0.5)  # 半透明
        self.root.attributes("-topmost", True)  # 窗口置顶

        # 设置透明色和鼠标穿透
        self.transparent_color = "#000001"
        self.root.attributes("-transparentcolor", self.transparent_color)

        # 实现鼠标不可穿透（点击穿透）
        self.set_click_through()

        # 获取所有显示器的信息
        self.monitors = self.get_monitors_info()

        # 创建每个显示器的窗口
        self.windows = []
        self.canvases = []
        self.circle_ids = []
        self.direction_labels = []
        self.status_labels = []

        for i, monitor in enumerate(self.monitors):
            # 为每个显示器创建一个窗口
            window = tk.Toplevel(self.root)
            window.overrideredirect(True)
            window.attributes("-alpha", 0.5)
            window.attributes("-topmost", True)
            window.attributes("-transparentcolor", self.transparent_color)

            # 设置窗口位置和大小
            x, y, width, height = monitor
            window.geometry(f"{width}x{height}+{x}+{y}")

            # 创建画布
            canvas = tk.Canvas(window, bg=self.transparent_color, highlightthickness=0)
            canvas.pack(fill=tk.BOTH, expand=True)

            # 创建方向显示标签
            direction_label = tk.Label(
                window,
                bg="black",
                fg="white",
                font=("Arial", 12, "bold"),
                padx=5,
                pady=2,
            )

            # 创建状态显示标签
            status_label = tk.Label(
                window,
                bg="black",
                fg="yellow",
                font=("Arial", 12, "bold"),
                padx=5,
                pady=2,
            )

            self.windows.append(window)
            self.canvases.append(canvas)
            self.circle_ids.append(None)
            self.direction_labels.append(direction_label)
            self.status_labels.append(status_label)

            # 设置点击穿透
            self.set_window_click_through(window)

        # 隐藏主窗口
        self.root.withdraw()

        self.center_x = 0  # 圆心X坐标
        self.center_y = 0  # 圆心Y坐标
        self.radius = 50  # 圆圈半径
        self.right_pressed = False  # 右键是否按下
        self.current_monitor = 0  # 当前活动的显示器索引

        # 右键按下初始信息
        self.right_press_start_time = None  # 右键按下的起始时间
        self.right_press_start_x = 0  # 右键按下的初始X坐标
        self.right_press_start_y = 0  # 右键按下的初始Y坐标
        self.circle_drawn = False  # 实心圆是否已绘制

        # 初始化计数变量（左键、中键、滚轮）
        self.left_count = 0
        self.middle_count = 0
        self.wheel_count = 0

        # 启动鼠标监听线程
        self.listener_thread = threading.Thread(target=self.start_listener, daemon=True)
        self.listener_thread.start()

        # 处理队列消息
        self.process_queue()

    # 获取所有显示器的信息
    def get_monitors_info(self):
        """获取所有显示器的位置和尺寸信息"""
        try:
            monitors = []
            # 使用ctypes获取显示器信息
            user32 = ctypes.windll.user32
            user32.SetProcessDPIAware()

            # 获取虚拟屏幕的尺寸
            virtual_width = user32.GetSystemMetrics(78)  # SM_CXVIRTUALSCREEN
            virtual_height = user32.GetSystemMetrics(79)  # SM_CYVIRTUALSCREEN
            virtual_x = user32.GetSystemMetrics(76)  # SM_XVIRTUALSCREEN
            virtual_y = user32.GetSystemMetrics(77)  # SM_YVIRTUALSCREEN

            # 枚举所有显示器
            enum_proc = ctypes.WINFUNCTYPE(
                ctypes.c_int,
                ctypes.c_ulong,
                ctypes.c_ulong,
                ctypes.POINTER(ctypes.wintypes.RECT),
                ctypes.c_double,
            )

            def callback(hMonitor, hdcMonitor, lprcMonitor, dwData):
                rect = lprcMonitor.contents
                monitors.append(
                    (
                        int(rect.left * self.scale_factor),
                        int(rect.top * self.scale_factor),
                        int((rect.right - rect.left) * self.scale_factor),
                        int((rect.bottom - rect.top) * self.scale_factor),
                    )
                )
                return 1

            c_callback = enum_proc(callback)
            user32.EnumDisplayMonitors(None, None, c_callback, 0)

            return monitors
        except:
            # 如果失败，返回主显示器的信息
            screen_width = int(self.root.winfo_screenwidth() * self.scale_factor)
            screen_height = int(self.root.winfo_screenheight() * self.scale_factor)
            return [(0, 0, screen_width, screen_height)]

    # 设置窗口为点击穿透
    def set_window_click_through(self, window):
        """设置窗口为点击穿透模式，允许鼠标事件穿过窗口"""
        try:
            # 获取窗口句柄
            hwnd = ctypes.windll.user32.GetParent(window.winfo_id())

            # 设置窗口扩展样式
            GWL_EXSTYLE = -20
            WS_EX_TRANSPARENT = 0x00000020
            WS_EX_LAYERED = 0x00080000

            # 获取当前扩展样式
            current_exstyle = ctypes.windll.user32.GetWindowLongW(hwnd, GWL_EXSTYLE)

            # 添加穿透和分层样式
            new_exstyle = current_exstyle | WS_EX_TRANSPARENT | WS_EX_LAYERED
            ctypes.windll.user32.SetWindowLongW(hwnd, GWL_EXSTYLE, new_exstyle)
        except Exception as e:
            print(f"设置点击穿透失败: {e}")

    # 设置主窗口为点击穿透
    def set_click_through(self):
        """设置主窗口为点击穿透模式"""
        self.set_window_click_through(self.root)

    # 获取系统DPI缩放比例
    def get_scale_factor(self):
        """获取当前屏幕的DPI缩放比例"""
        try:
            user32 = ctypes.windll.user32
            user32.SetProcessDPIAware()  # 设置进程为DPI感知
            # dpi = user32.GetDpiForSystem()
            user32.GetDpiForSystem()
            return 1.0  # dpi / 96.0  # 96是默认DPI
        except:
            return 1.0  # 出错时默认使用1.0缩放比例

    # 将原始坐标转换为缩放后的坐标
    def convert_coordinates(self, x, y):
        """根据缩放比例转换坐标"""
        return int(x * self.scale_factor), int(y * self.scale_factor)

    # 确定鼠标所在的显示器
    def get_monitor_index(self, x, y):
        """根据坐标确定鼠标所在的显示器索引"""
        for i, (mon_x, mon_y, mon_width, mon_height) in enumerate(self.monitors):
            if mon_x <= x < mon_x + mon_width and mon_y <= y < mon_y + mon_height:
                return i
        return 0  # 默认返回第一个显示器

    def start_listener(self):
        """启动鼠标监听器，包括点击、移动和滚轮事件"""
        with mouse.Listener(
            on_click=self.on_click,
            on_move=self.on_move,
            on_scroll=self.on_scroll,  # 添加滚轮事件监听
        ) as listener:
            listener.join()

    def on_click(self, x, y, button, pressed):
        """处理鼠标点击事件"""
        # 转换坐标以适应DPI缩放
        scaled_x, scaled_y = self.convert_coordinates(x, y)

        # 确定当前显示器
        self.current_monitor = self.get_monitor_index(scaled_x, scaled_y)

        if button == mouse.Button.right:
            self.right_pressed = pressed
            if pressed:
                # 右键按下，记录初始信息并立即绘制圆
                self.center_x, self.center_y = scaled_x, scaled_y
                self.right_press_start_x, self.right_press_start_y = scaled_x, scaled_y
                self.right_press_start_time = time.time()  # 记录按下时间
                self.circle_drawn = True  # 标记已绘制
                # 重置计数
                self.left_count = 0
                self.middle_count = 0
                self.wheel_count = 0
                # 立即绘制圆
                self.queue.put(
                    ("draw", self.current_monitor, self.center_x, self.center_y)
                )
            else:
                # 右键松开，清除圆和标签
                self.queue.put(("clear", self.current_monitor))
                self.queue.put(("hide_direction", self.current_monitor))
                self.queue.put(("hide_status", self.current_monitor))
                # 重置状态变量
                self.right_press_start_time = None
                self.circle_drawn = False
                # 重置计数
                self.left_count = 0
                self.middle_count = 0
                self.wheel_count = 0

        # 处理左键点击（仅在右键按住且鼠标在圈内时）
        elif (
            button == mouse.Button.left
            and pressed
            and self.right_pressed
            and self.circle_ids[self.current_monitor] is not None
        ):
            if self._is_inside_circle(scaled_x, scaled_y):
                self.left_count += 1
                if self.left_count >= 6:  # 左键计数到6重置
                    self.left_count = 0
                self.queue.put(
                    ("update_status", self.current_monitor, scaled_x, scaled_y)
                )

        # 处理中键点击（仅在右键按住且鼠标在圈内时）
        elif (
            button == mouse.Button.middle
            and pressed
            and self.right_pressed
            and self.circle_ids[self.current_monitor] is not None
        ):
            if self._is_inside_circle(scaled_x, scaled_y):
                self.middle_count += 1
                if self.middle_count >= 4:  # 中键计数到4重置
                    self.middle_count = 0
                self.queue.put(
                    ("update_status", self.current_monitor, scaled_x, scaled_y)
                )

    def on_scroll(self, x, y, dx, dy):
        """处理鼠标滚轮事件"""
        # 转换坐标以适应DPI缩放
        scaled_x, scaled_y = self.convert_coordinates(x, y)

        # 确定当前显示器
        self.current_monitor = self.get_monitor_index(scaled_x, scaled_y)

        # 仅在右键按住且鼠标在圈内时计数
        if (
            self.right_pressed
            and self.circle_ids[self.current_monitor] is not None
            and self._is_inside_circle(scaled_x, scaled_y)
        ):
            self.wheel_count += 1
            if self.wheel_count >= 5:  # 滚轮计数到5重置
                self.wheel_count = 0
            self.queue.put(("update_status", self.current_monitor, scaled_x, scaled_y))

    def on_move(self, x, y):
        """处理鼠标移动事件"""
        # 转换坐标以适应DPI缩放
        scaled_x, scaled_y = self.convert_coordinates(x, y)

        # 确定当前显示器
        self.current_monitor = self.get_monitor_index(scaled_x, scaled_y)

        if self.right_pressed and self.circle_ids[self.current_monitor] is not None:
            # 计算鼠标与圆心的距离
            distance = self._get_distance(scaled_x, scaled_y)

            # 如果鼠标在圆圈外，显示方向标签，隐藏状态标签
            if distance > self.radius:
                direction = self.get_direction(
                    scaled_x - self.center_x, scaled_y - self.center_y
                )
                self.queue.put(
                    (
                        "show_direction",
                        self.current_monitor,
                        scaled_x,
                        scaled_y,
                        direction,
                    )
                )
                self.queue.put(("hide_status", self.current_monitor))
            else:
                # 鼠标在圆圈内，隐藏方向标签，更新状态标签
                self.queue.put(("hide_direction", self.current_monitor))
                self.queue.put(
                    ("update_status", self.current_monitor, scaled_x, scaled_y)
                )

    def _is_inside_circle(self, x, y):
        """判断点是否在圆圈内"""
        return self._get_distance(x, y) <= self.radius

    def _get_distance(self, x, y):
        """计算点到圆心的距离"""
        dx = x - self.center_x
        dy = y - self.center_y
        return math.hypot(dx, dy)  # 使用math库的hypot计算距离

    def get_direction(self, dx, dy):
        """根据相对坐标计算方向"""
        # 计算角度（弧度）
        angle = math.atan2(dy, dx) * 180 / math.pi

        # 调整角度，使其以向上为0度
        if angle >= 0:
            angle += 90
        elif angle < -90:
            angle = 360 + 90 + angle
        elif angle < 0:
            angle = 90 + angle

        # 根据角度判断方向
        if 22.5 <= angle < 67.5:
            return "右上"
        elif 67.5 <= angle < 112.5:
            return "右"
        elif 112.5 <= angle < 157.5:
            return "右下"
        elif 157.5 <= angle < 202.5:
            return "下"
        elif 202.5 <= angle < 247.5:
            return "左下"
        elif 247.5 <= angle < 292.5:
            return "左"
        elif 292.5 <= angle < 337.5:
            return "左上"
        else:
            return "上"

    def process_queue(self):
        """处理队列中的消息"""
        while not self.queue.empty():
            command = self.queue.get()
            if command[0] == "draw":
                # 绘制实心圆
                monitor_idx, x, y = command[1], command[2], command[3]
                # 获取当前显示器的偏移量
                mon_x, mon_y, mon_width, mon_height = self.monitors[monitor_idx]
                # 转换为相对于当前显示器的坐标
                rel_x = x - mon_x
                rel_y = y - mon_y

                if self.circle_ids[monitor_idx]:
                    self.canvases[monitor_idx].delete(self.circle_ids[monitor_idx])
                # 绘制实心圆
                self.circle_ids[monitor_idx] = self.canvases[monitor_idx].create_oval(
                    rel_x - self.radius,
                    rel_y - self.radius,
                    rel_x + self.radius,
                    rel_y + self.radius,
                    fill="red",  # 填充颜色，实现实心圆
                    outline="red",  # 边框颜色
                    width=2,
                )
                # 激活窗口
                self.windows[monitor_idx].focus_force()
            elif command[0] == "clear":
                # 清除圆圈
                monitor_idx = command[1]
                if self.circle_ids[monitor_idx]:
                    self.canvases[monitor_idx].delete(self.circle_ids[monitor_idx])
                    self.circle_ids[monitor_idx] = None
            elif command[0] == "show_direction":
                # 显示方向标签
                monitor_idx, x, y, direction = (
                    command[1],
                    command[2],
                    command[3],
                    command[4],
                )
                # 获取当前显示器的偏移量
                mon_x, mon_y, mon_width, mon_height = self.monitors[monitor_idx]
                # 转换为相对于当前显示器的坐标
                rel_x = x - mon_x
                rel_y = y - mon_y
                # 确保标签显示在鼠标上方且不超出屏幕
                label_x = min(max(rel_x - 20, 0), mon_width - 60)
                label_y = max(rel_y - 30, 0)
                self.direction_labels[monitor_idx].config(text=direction)
                self.direction_labels[monitor_idx].place(x=label_x, y=label_y)
            elif command[0] == "hide_direction":
                # 隐藏方向标签
                monitor_idx = command[1]
                self.direction_labels[monitor_idx].place_forget()
            elif command[0] == "update_status":
                # 更新并显示状态标签（左键、中键、滚轮计数）
                monitor_idx, x, y = command[1], command[2], command[3]
                # 获取当前显示器的偏移量
                mon_x, mon_y, mon_width, mon_height = self.monitors[monitor_idx]
                # 转换为相对于当前显示器的坐标
                rel_x = x - mon_x
                rel_y = y - mon_y
                # 只有当计数不为0时才显示
                if self.left_count > 0 or self.middle_count > 0 or self.wheel_count > 0:
                    status_text = f"左: {self.left_count}, 中: {self.middle_count}, 滚: {self.wheel_count}"
                    # 确保标签显示在鼠标上方且不超出屏幕
                    label_x = min(max(rel_x - 80, 0), mon_width - 160)
                    label_y = max(rel_y - 30, 0)
                    self.status_labels[monitor_idx].config(text=status_text)
                    self.status_labels[monitor_idx].place(x=label_x, y=label_y)
                else:
                    self.status_labels[monitor_idx].place_forget()
            elif command[0] == "hide_status":
                # 隐藏状态标签
                monitor_idx = command[1]
                self.status_labels[monitor_idx].place_forget()

        # 定期检查队列
        self.root.after(10, self.process_queue)

    def run(self):
        """运行主循环"""
        self.root.mainloop()


if __name__ == "__main__":
    drawer = MouseCircleDrawer()
    drawer.run()
