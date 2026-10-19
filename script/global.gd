extends Node

var directions = {
	"ui_up":Vector2.UP,
	"ui_down":Vector2.DOWN,
	"ui_left":Vector2.LEFT,
	"ui_right":Vector2.RIGHT,
}

const DISTANCE = 64
const LEVEL_DIR = "res://levels_txt/"
const LEVEL_SCENE = "res://scene/LevelTemplate.tscn"

# 关卡列表缓存：扫描结果过滤 Level*.txt 并排序，运行期不会变化
var _level_list: Array = []
# 当前关卡索引（0 基），由 goto_level 维护
var current_level_index: int = 0

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
				if not dir.current_is_dir() and filename.begins_with("Level") and filename.ends_with(".txt"):
					_level_list.append(LEVEL_DIR + filename)
				filename = dir.get_next()
			dir.list_dir_end()
		_level_list.sort()
	return _level_list

func get_current_level_index() -> int:
	return current_level_index

func goto_level(index: int) -> void:
	var list = get_level_list()
	if index >= 0 and index < list.size():
		current_level_index = index
		get_tree().change_scene(LEVEL_SCENE)

func get_level_display_name(path: String) -> String:
	return path.get_file().get_basename()

# 解析标准 sokoban ASCII 关卡文件（首行 "; origin=(x,y)" 为网格原点）
# 返回 {walls: PoolVector2Array, dests: PoolVector2Array, boxes: PoolVector2Array, player: Vector2}
# 坐标为真实网格坐标（已加 origin），世界像素 = 网格 * 64
func load_level_data(path: String) -> Dictionary:
	var f = File.new()
	if f.open(path, File.READ) != OK:
		push_error("无法打开关卡文件: " + path)
		return {}
	var origin := Vector2.ZERO
	var rows: Array = []
	while not f.eof_reached():
		var line: String = f.get_line()
		if line.begins_with(";"):
			var s: String = line.substr(line.find("(") + 1)
			s = s.substr(0, s.length() - 1)
			var parts = s.split(",")
			origin = Vector2(int(parts[0]), int(parts[1]))
		else:
			rows.append(line)
	f.close()
	# 去掉文件尾部空行
	while rows.size() > 0 and String(rows[rows.size() - 1]).strip_edges() == "":
		rows.pop_back()

	var walls := PoolVector2Array()
	var dests := PoolVector2Array()
	var boxes := PoolVector2Array()
	var player := Vector2(-9999, -9999)
	for j in rows.size():
		var row: String = rows[j]
		for i in row.length():
			var cell := Vector2(origin.x + i, origin.y + j)
			var ch: String = row[i]
			if ch == "#":
				walls.append(cell)
			elif ch == ".":
				dests.append(cell)
			elif ch == "$":
				boxes.append(cell)
			elif ch == "*":
				boxes.append(cell)
				dests.append(cell)
			elif ch == "@":
				player = cell
			elif ch == "+":
				player = cell
				dests.append(cell)
	if player.x < -9000:
		push_error("关卡缺少玩家: " + path)
		return {}
	return {"walls": walls, "dests": dests, "boxes": boxes, "player": player}
