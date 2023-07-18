extends Panel

func _ready():
	for item in $Control.get_children():
		item.connect("pressed",self,"bt_press",[item.name])
	

func bt_press(name):
	get_tree().change_scene("res://level/" + name + ".tscn")
