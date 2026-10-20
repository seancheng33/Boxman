extends Label

# 变量：先把要用的字存起来
var greeting = "这行字是代码改的！"

# _ready：节点进场时引擎会自动调用的函数
func _ready():
	# 改文字：跟在检查器里填 Text 效果一样
	text = greeting
	# print：把消息打到编辑器的输出面板
	print("脚本跑起来了！")
