画一个圆
把标题栏去掉，半透明度，不在任务栏显示图标
窗口置顶
鼠标不穿透
激活圆
鼠标在圆内则激活圆
隐藏而不摧毁圆
鼠标在圆外时显示方位
在圆外松开右键去执行两个简单的操作
重命名函数和变量
创建3个变量，按下右键不松开时，
  鼠标在圆内左键单击，中键点击，滚动滚轮分别让这3个变量递增，
  另外在定义3个变量，分别为6,4,5，
  前面3个变量分别递增到后面3个变量的值时，不再往上递增，而变为0，
  在圆内tooltip前面3个变量的值
3个变量，8个方位，当松开右键时，有7*5*6*8=1680种不同的操作，
  目前3个变量都为0时，右上和右下分别有一个操作，
  改变代码结构，把1680种不同的操作封装成不同的不带参数的函数，
  按下右键时，当鼠标在圆内时，根据当前3个变量的值，tooltip下8个方位的操作函数名，
  当鼠标在圆外时，显示：“当松开右键时执行的操作函数名”
Action_0_0_0_D不以这种格式去命名函数，直接以这个函数要执行的操作去命名
按下右键不松开时，tooltip的内容一闪一闪的，
  另外tooltip的格式不够直观，最好能够直观的看到8个方位的操作
  （不够直观）
  方向箭头
格式化代码
其中ExampleFunction1改成如下功能：
  松开右键之后，换一下RButton，LButton，MButton，WheelUp，WheelDown热键，
  RButton：恢复热键
  LButton：暂停或播放音乐
  MButton：静音或取消静音
  WheelUp：音量加
  WheelDown：音量减
不要用g_MediaMode，因为我还想ExampleFunction2也改一下热键，
  不然的话有需要增加一个变量，导致#HotIf !g_MediaMode这行会变得很长
仿照以上代码，实现我想要的功能：
  RButton热键不变
  LButton Down:: 移动鼠标下的窗口
  LButton Down:: 结束鼠标下的窗口的移动
  MButton Down:: 改变鼠标下的窗口的大小
  MButton Up:: 结束改变鼠标下的窗口的大小
  WheelUp:: 增大鼠标下窗口的透明度
  WheelDown:: 减小鼠标下窗口的透明度
当为normal模式时，ActionFunction使用g_ActionFunctionMap，
  当为window_control模式时，ActionFunction使用另一个map，
  即不同模式如果需要的话，可以用不同的g_ActionFunctionMap，
  可以改变g_ActionFunctionMap的结构，接受不同模式作为键
