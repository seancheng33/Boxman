extends Control

# 教学演示：主菜单——场景切换与游戏流程
# 打开游戏先见到它：开始 / 继续 / 退出
# 「继续」只在有进度时出现，进不进得去由存档说了算

const SAVE_PATH := "user://progress.cfg"
const DEFAULT_UNLOCKED := 5

@onready var start_btn := $StartBtn
@onready var continue_btn := $ContinueBtn

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var n := mini(cfg.get_value("progress", "unlocked", DEFAULT_UNLOCKED), 7)
		if n > DEFAULT_UNLOCKED:
			continue_btn.text = "继续（已解锁 %d 关）" % n
			continue_btn.visible = true
			continue_btn.grab_focus()
			return
	# 没进度：藏起继续按钮，焦点给开始
	continue_btn.visible = false
	start_btn.grab_focus()

func _on_start() -> void:
	get_tree().change_scene_to_file("res://select_page_demo.tscn")

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://select_page_demo.tscn")

func _on_quit() -> void:
	get_tree().quit()
