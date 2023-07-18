extends Node2D

var scene_list = GlobalVar.get_level_list()

var scene_index = 0

func _ready():
	var filename = get_tree().current_scene.filename
	for value in scene_list.values():
		if value == filename:
			break;
		else:
			scene_index += 1

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://scene/MainTitle.tscn")

func _on_next_pressed():
	get_tree().paused = false
	if scene_index != scene_list.size() - 1 :
		get_tree().change_scene(scene_list[scene_index + 1])
	else:
		$next.text = "已是最后一关！"
