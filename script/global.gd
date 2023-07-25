extends Node

var directions = {
	"ui_up":Vector2.UP,
	"ui_down":Vector2.DOWN,
	"ui_left":Vector2.LEFT,
	"ui_right":Vector2.RIGHT,
}

const DISTANCE = 64

func check_finish(destinations):
	var finish_num = 0
	for destination in destinations:
		if destination.isActive == true:
			finish_num += 1
	if finish_num == destinations.size():
		return true
	else:
		return false
   
func get_level_list():
	var file_list = {}
	var dir = Directory.new()
	if dir.open("res://level/") == OK:
		dir.list_dir_begin()
		var filename = dir.get_next()
		var i = 0
		while filename != "":
			if filename == "." or filename == "..":
				filename = dir.get_next()
				continue
			file_list[i] = "res://level/"+filename
			filename = dir.get_next()
			i += 1
		dir.list_dir_end()
	return file_list
