extends Node2D

var scene_list = GlobalVar.get_level_list()

var scene_index = 0

func _ready():
	var filename = get_tree().current_scene.filename
	if filename == scene_list.get(0):
		$Panel/previous.disabled = true
	elif filename == scene_list.get(scene_list.size()-1):
		$Panel/next.disabled = true
		
	for value in scene_list.values():
		if value == filename:
			break;
		else:
			scene_index += 1
			
	$Panel/Label2.text = "当前关卡： " + filename.split("/")[3].split(".")[0]

func _on_back_pressed():
	get_tree().change_scene("res://scene/MainTitle.tscn")

func _on_reset_pressed():
	get_tree().reload_current_scene()

func _on_previous_pressed():
	get_tree().change_scene(scene_list[scene_index - 1])

func _on_next_pressed():
	get_tree().change_scene(scene_list[scene_index + 1])
