# 分析以下题目，并给出对应的答案解析，要求：
# 1. 分析题目，给出简要的解题思路
# 2. 提供最终答案或示例代码
# 3. 必要时对答案进行解释或补充。
# 以下是待解析的题目：
# python用pynput时时刻刻监测鼠标，当鼠标右键按下时，用tkinter库以按下的位置为圆心画一个圆圈，当鼠标右键松开时关掉该圆圈
# 按住右键当移动到圆圈外后，在鼠标上方实时显示相对于圆心的位置，共8个：上，下，左，右，右上，右下，左下，左上，松开右键后结束显示

import tkinter as tk
from pynput import mouse
import threading
from queue import Queue


class MouseCircleDrawer:
    def __init__(self):
        # 创建消息队列用于线程间通信
        self.queue = Queue()

        # 创建主窗口
        self.root = tk.Tk()
        self.root.overrideredirect(True)  # 无边框窗口
        self.root.attributes("-alpha", 0.5)  # 半透明
        self.root.attributes("-topmost", True)  # 窗口置顶

        # 设置透明色
        self.transparent_color = "#000001"
        self.root.attributes("-transparentcolor", self.transparent_color)

        self.screen_width = self.root.winfo_screenwidth()
        self.screen_height = self.root.winfo_screenheight()
        self.root.geometry(f"{self.screen_width}x{self.screen_height}+0+0")

        # 创建画布
        self.canvas = tk.Canvas(
            self.root, bg=self.transparent_color, highlightthickness=0
        )
        self.canvas.pack(fill=tk.BOTH, expand=True)

        # 创建方向显示标签
        self.direction_label = tk.Label(
            self.root,
            bg="black",
            fg="white",
            font=("Arial", 12, "bold"),
            padx=5,
            pady=2,
        )

        self.circle_id = None  # 用于存储圆圈的ID
        self.center_x = 0  # 圆心X坐标
        self.center_y = 0  # 圆心Y坐标
        self.radius = 30  # 圆圈半径
        self.right_pressed = False  # 右键是否按下

        # 启动鼠标监听线程
        self.listener_thread = threading.Thread(target=self.start_listener, daemon=True)
        self.listener_thread.start()

        # 处理队列消息
        self.process_queue()

    def start_listener(self):
        """启动鼠标监听器，包括点击和移动事件"""
        with mouse.Listener(on_click=self.on_click, on_move=self.on_move) as listener:
            listener.join()

    def on_click(self, x, y, button, pressed):
        """处理鼠标点击事件"""
        if button == mouse.Button.right:
            self.right_pressed = pressed
            if pressed:
                # 右键按下，记录圆心位置并发送绘制命令
                self.center_x, self.center_y = x, y
                self.queue.put(("draw", x, y))
            else:
                # 右键松开，发送清除命令并隐藏方向标签
                self.queue.put(("clear",))
                self.queue.put(("hide_direction",))

    def on_move(self, x, y):
        """处理鼠标移动事件"""
        if self.right_pressed and self.circle_id:
            # 计算鼠标与圆心的距离
            dx = x - self.center_x
            dy = y - self.center_y
            distance = (dx**2 + dy**2) ** 0.5

            # 如果鼠标在圆圈外，计算方向并显示
            if distance > self.radius:
                direction = self.get_direction(dx, dy)
                self.queue.put(("show_direction", x, y, direction))
            else:
                # 鼠标在圆圈内，隐藏方向标签
                self.queue.put(("hide_direction",))

    def get_direction(self, dx, dy):
        """根据相对坐标计算方向"""
        # 计算角度（弧度）
        import math

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
                # 绘制圆圈
                x, y = command[1], command[2]
                if self.circle_id:
                    self.canvas.delete(self.circle_id)
                self.circle_id = self.canvas.create_oval(
                    x - self.radius,
                    y - self.radius,
                    x + self.radius,
                    y + self.radius,
                    outline="red",
                    width=2,
                )
            elif command[0] == "clear":
                # 清除圆圈
                if self.circle_id:
                    self.canvas.delete(self.circle_id)
                    self.circle_id = None
            elif command[0] == "show_direction":
                # 显示方向标签
                x, y, direction = command[1], command[2], command[3]
                # 确保标签显示在鼠标上方且不超出屏幕
                label_x = min(max(x - 20, 0), self.screen_width - 60)
                label_y = max(y - 30, 0)
                self.direction_label.config(text=direction)
                self.direction_label.place(x=label_x, y=label_y)
            elif command[0] == "hide_direction":
                # 隐藏方向标签
                self.direction_label.place_forget()

        # 定期检查队列
        self.root.after(10, self.process_queue)

    def run(self):
        """运行主循环"""
        self.root.mainloop()


if __name__ == "__main__":
    drawer = MouseCircleDrawer()
    drawer.run()
