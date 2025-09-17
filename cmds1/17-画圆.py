# 分析以下题目，并给出对应的答案解析，要求：
# 1. 分析题目，给出简要的解题思路
# 2. 提供最终答案或示例代码
# 3. 必要时对答案进行解释或补充。
# 以下是待解析的题目：
# python用pynput时时刻刻监测鼠标，当鼠标右键按下时，用tkinter库以按下的位置为圆心画一个圆圈，当鼠标右键松开时关掉该圆圈

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

        # 修复：设置透明色
        # 使用一个特殊颜色作为透明标记
        self.transparent_color = "#000001"
        self.root.attributes("-transparentcolor", self.transparent_color)

        self.root.geometry(
            f"{self.root.winfo_screenwidth()}x{self.root.winfo_screenheight()}+0+0"
        )

        # 修复：使用透明色作为画布背景，替代不兼容的systemTransparent
        self.canvas = tk.Canvas(
            self.root, bg=self.transparent_color, highlightthickness=0
        )
        self.canvas.pack(fill=tk.BOTH, expand=True)

        self.circle_id = None  # 用于存储圆圈的ID

        # 启动鼠标监听线程
        self.listener_thread = threading.Thread(target=self.start_listener, daemon=True)
        self.listener_thread.start()

        # 处理队列消息
        self.process_queue()

    def start_listener(self):
        """启动鼠标监听器"""
        with mouse.Listener(on_click=self.on_click) as listener:
            listener.join()

    def on_click(self, x, y, button, pressed):
        """处理鼠标点击事件"""
        if button == mouse.Button.right:
            if pressed:
                # 右键按下，发送绘制命令和位置
                self.queue.put(("draw", x, y))
            else:
                # 右键松开，发送清除命令
                self.queue.put(("clear",))

    def process_queue(self):
        """处理队列中的消息"""
        while not self.queue.empty():
            command = self.queue.get()
            if command[0] == "draw":
                # 绘制圆圈
                x, y = command[1], command[2]
                radius = 30  # 圆圈半径
                if self.circle_id:
                    self.canvas.delete(self.circle_id)
                self.circle_id = self.canvas.create_oval(
                    x - radius,
                    y - radius,
                    x + radius,
                    y + radius,
                    outline="red",
                    width=2,
                )
            elif command[0] == "clear":
                # 清除圆圈
                if self.circle_id:
                    self.canvas.delete(self.circle_id)
                    self.circle_id = None

        # 定期检查队列
        self.root.after(10, self.process_queue)

    def run(self):
        """运行主循环"""
        self.root.mainloop()


if __name__ == "__main__":
    drawer = MouseCircleDrawer()
    drawer.run()
