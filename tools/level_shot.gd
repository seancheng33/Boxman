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
	# SCENE_PATH 可指定任意场景（如选关界面）；默认截关卡模板（索引由 BOXMAN_LEVEL 控制）
	var scene_path := OS.get_environment("SCENE_PATH")
	if scene_path == "":
		scene_path = "res://scene/LevelTemplate.tscn"
	change_scene(scene_path)

func _capture():
	var img := root.get_viewport().get_texture().get_data()
	img.flip_y()
	var out := OS.get_environment("SHOT_PATH")
	if out == "":
		out = "user://level_shot.png"
	img.save_png(out)
	print("SHOT_SAVED: ", out)
	quit()
