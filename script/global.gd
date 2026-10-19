extends Node

var directions = {
	"ui_up":Vector2.UP,
	"ui_down":Vector2.DOWN,
	"ui_left":Vector2.LEFT,
	"ui_right":Vector2.RIGHT,
}

const DISTANCE = 64
const LEVEL_DIR = "res://level/"

# 关卡列表缓存：扫描结果过滤 .tscn 并排序，运行期不会变化
var _level_list: Array = []

func check_finish(destinations):
	var finish_num = 0
	for destination in destinations:
		if destination.is_active:
			finish_num += 1
	return finish_num == destinations.size()

func get_level_list() -> Array:
	if _level_list.empty():
		var dir = Directory.new()
		if dir.open(LEVEL_DIR) == OK:
			dir.list_dir_begin()
			var filename = dir.get_next()
			while filename != "":
				if not dir.current_is_dir() and filename.ends_with(".tscn"):
					_level_list.append(LEVEL_DIR + filename)
				filename = dir.get_next()
			dir.list_dir_end()
		_level_list.sort()
	return _level_list

func get_current_level_index() -> int:
	var filename = get_tree().current_scene.filename
	return get_level_list().find(filename)

func goto_level(index: int) -> void:
	var list = get_level_list()
	if index >= 0 and index < list.size():
		get_tree().change_scene(list[index])

func get_level_display_name(path: String) -> String:
	return path.get_file().get_basename()
