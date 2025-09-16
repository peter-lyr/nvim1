import tkinter as tk
from tkinter import Canvas
from pynput import mouse
import ctypes
import threading

# import os
# def pip_install(plugin):
#     os.system(
#         f"pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com {plugin}"
#     )
# pip_install('pynput')


# 获取Windows系统缩放比例
def get_scaling_factor():
    user32 = ctypes.windll.user32
    user32.SetProcessDPIAware()
    return user32.GetDpiForSystem() / 96  # 96是100%缩放时的DPI


# 全局变量
circle_window = None
scaling_factor = (
    get_scaling_factor()
)  # 调用之后就手动给1，没调用就手动给实际的缩放比例，如1.25
scaling_factor = 1
root = None  # 主窗口引用
circle_radius = 100  # 圆形半径（逻辑像素）


# 绘制圆形的函数
def draw_circle(x, y):
    global circle_window

    # 关闭已存在的窗口
    close_circle()

    # 创建顶层窗口
    circle_window = tk.Toplevel(root)
    circle_window.overrideredirect(True)  # 无边框
    circle_window.attributes("-alpha", 0.5)  # 半透明
    circle_window.attributes("-topmost", True)  # 置顶

    # 设置透明色
    transparent_color = "#fffffe"
    circle_window.attributes("-transparentcolor", transparent_color)

    # 窗口大小为直径的2倍（半径*2）
    window_size = circle_radius * 2
    # 创建画布
    canvas = Canvas(
        circle_window,
        width=window_size,
        height=window_size,
        bg=transparent_color,
        highlightthickness=0,
    )
    canvas.pack()

    # 绘制圆形
    canvas.create_oval(5, 5, window_size - 5, window_size - 5, outline="red", width=2)

    # 精确计算窗口位置：
    # 1. 将pynput获取的物理坐标转换为Tkinter使用的逻辑坐标
    logical_x = x / scaling_factor
    logical_y = y / scaling_factor

    # 2. 计算窗口左上角位置，使鼠标位置位于圆心
    window_x = int(logical_x - circle_radius)
    window_y = int(logical_y - circle_radius)

    circle_window.geometry(f"{window_size}x{window_size}+{window_x}+{window_y}")
    # 调试信息，方便查看坐标转换是否正确
    # print(f"物理坐标: ({x}, {y}), 逻辑坐标: ({logical_x:.0f}, {logical_y:.0f}), 窗口位置: ({window_x}, {window_y})")


# 关闭圆形窗口
def close_circle():
    global circle_window
    if circle_window is not None and isinstance(circle_window, tk.Toplevel):
        circle_window.destroy()
        circle_window = None


# 线程安全的UI操作包装函数
def safe_draw_circle(x, y):
    if root:
        root.after(0, lambda: draw_circle(x, y))


def safe_close_circle():
    if root:
        root.after(0, close_circle)


# 鼠标事件处理
def on_click(x, y, button, pressed):
    if button == mouse.Button.right:
        if pressed:
            # 右键按下，线程安全地绘制圆形
            safe_draw_circle(x, y)
        else:
            # 右键松开，线程安全地关闭圆形
            safe_close_circle()


# 启动监听
def main():
    global root
    # 创建主窗口
    root = tk.Tk()
    root.withdraw()  # 隐藏主窗口

    # 在单独线程中启动鼠标监听
    def start_listener():
        with mouse.Listener(on_click=on_click) as listener:
            listener.join()

    listener_thread = threading.Thread(target=start_listener, daemon=True)
    listener_thread.start()

    # 启动Tkinter事件循环
    root.mainloop()


if __name__ == "__main__":
    main()
