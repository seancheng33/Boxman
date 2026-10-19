extends Node2D

func _ready():
	$Label2.text = GlobalVar.t("win.msg")
	$quit.text = GlobalVar.t("win.quit")
	$next.text = GlobalVar.t("win.next")
	var scene_index = GlobalVar.get_current_level_index()
	var level_count = GlobalVar.get_level_list().size()
	if scene_index >= level_count - 1:
		$next.disabled = true
		$next.text = GlobalVar.t("win.last")

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://scene/MainTitle.tscn")

func _on_next_pressed():
	get_tree().paused = false
	GlobalVar.goto_level(GlobalVar.get_current_level_index() + 1)
