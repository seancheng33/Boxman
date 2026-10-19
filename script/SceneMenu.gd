extends Node2D

func _ready():
	var scene_index = GlobalVar.get_current_level_index()
	var level_count = GlobalVar.get_level_list().size()
	$Panel/previous.disabled = scene_index <= 0
	$Panel/next.disabled = scene_index >= level_count - 1
	$Panel/Label2.text = "当前关卡： " + GlobalVar.get_level_display_name(get_tree().current_scene.filename)

func _on_back_pressed():
	get_tree().change_scene("res://scene/MainTitle.tscn")

func _on_reset_pressed():
	get_tree().reload_current_scene()

func _on_previous_pressed():
	GlobalVar.goto_level(GlobalVar.get_current_level_index() - 1)

func _on_next_pressed():
	GlobalVar.goto_level(GlobalVar.get_current_level_index() + 1)
