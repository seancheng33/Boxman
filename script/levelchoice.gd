extends Panel

func _ready():
	for item in $Control.get_children():
		item.connect("pressed",self,"bt_press",[item.name])
	

func bt_press(level_name):
	var path = "res://level/" + level_name + ".tscn"
	if ResourceLoader.exists(path):
		get_tree().change_scene(path)
