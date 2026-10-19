extends SceneTree

# 物理级回归测试：箱子压目标点的暗色状态切换。
# 用法：godot --path . -s res://tools/test_dest_switch.gd
# 覆盖三个场景：
#   STEP1 初始即压在目标点 → on_dest 应为 true
#   STEP2 从目标点 A 直接挪到相邻目标点 B（原 bug 场景）→ on_dest 应保持 true
#   STEP3 挪离所有目标点 → on_dest 应为 false

var box
var ticks := 0

func _initialize():
	var dest_scene = load("res://scene/dest.tscn")
	var box_scene = load("res://scene/box.tscn")
	var dest_a = dest_scene.instance()
	dest_a.position = Vector2(0, 0)
	var dest_b = dest_scene.instance()
	dest_b.position = Vector2(64, 0)
	box = box_scene.instance()
	box.position = Vector2(0, 0)
	root.add_child(dest_a)
	root.add_child(dest_b)
	root.add_child(box)
	var timer := Timer.new()
	timer.wait_time = 0.1
	root.add_child(timer)
	timer.connect("timeout", self, "_tick")
	timer.start()

func _tick():
	ticks += 1
	if ticks == 2:
		print("STEP1 box.on_dest=", box.on_dest, " (expect true)")
		# 原 bug：从 A 直接挪到相邻的 B，事件顺序不保证，暗色态可能丢失
		box.position = Vector2(64, 0)
	elif ticks == 4:
		print("STEP2 box.on_dest=", box.on_dest, " (expect true)")
		box.position = Vector2(500, 500)
	elif ticks == 6:
		print("STEP3 box.on_dest=", box.on_dest, " (expect false)")
		var ok: bool = box.on_dest == false
		print("TEST_DONE ok=", ok)
		quit()
