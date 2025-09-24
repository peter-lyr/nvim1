从cmds1\02-ahk\02-rbutton-circle.ahk
  拷贝到cmds1\03-ahk-mouse\RadialMouseCommander.ahk
  并问deepseek把它拆分成多个文件
把以上代码分割成多个文件，按照一下思路：
  刚启动时处于normal模式，按下按下右键可以选择8个方位执行操作或切换模式，
  不同模式单独用一个文件，类似操作放到一个文件里去，
  main.ahk里单独配置normal模式下，8个方位执行操作和切换模式的mapping，
  其他模式的文件里去配置它们自己的mapping，比如window_control_mode.ahk，
  其他函数按照功能放到不同的文件，它们只存放一些函数，用于在各种模式的文件里去调用
  不要修改函数或变量，直接把代码剪切到相应的文件中去
更快捷的热键
  左键单击 → 按住右键 → 松开左键：g_LeftButtonState = 1
  左键双击 → 按住右键 → 松开左键：g_LeftButtonState = 2
  左键三次点击 → 按住右键 → 松开左键：g_LeftButtonState = 3
  中键单击 → 按住右键 → 松开中键：g_MiddleButtonState = 1
  中键双击 → 按住右键 → 松开中键：g_MiddleButtonState = 2
  中键三次点击 → 按住右键 → 松开中键：g_MiddleButtonState = 3
  松开中键或左键后，右键没松，此时画圆，
  此时左键单击，中键单击，滚动滚轮都能继续改变g_LeftButtonState，g_MiddleButtonState，g_WheelButtonState这三个值
