extends SceneTree

# 临时工具：启动指定关卡并截图，用于分关配色的视觉验证。
# 用法：BOXMAN_LEVEL=<索引> SHOT_PATH=<输出png> godot --path . -s res://tools/level_shot.gd
# 截图后自动退出，不进入正式游戏流程。

func _initialize():
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	root.add_child(timer)
	timer.connect("timeout", self, "_capture")
	timer.start()
	# 关卡索引由 level_builder._apply_env_override 从 BOXMAN_LEVEL 读取
	change_scene("res://scene/LevelTemplate.tscn")

func _capture():
	var img := root.get_viewport().get_texture().get_data()
	img.flip_y()
	var out := OS.get_environment("SHOT_PATH")
	if out == "":
		out = "user://level_shot.png"
	img.save_png(out)
	print("SHOT_SAVED: ", out)
	quit()
