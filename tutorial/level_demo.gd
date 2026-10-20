extends Node2D

# 教学演示：把关卡写成一份文本，代码只管读
# 地图不再写死在逻辑里，改关卡就是改那几行字

const CELL := 32
const WALL := "#"

# 关卡就是一段文本，用的是推箱子社区通用的符号：
#   #  墙              空格  地板
#   $  箱子            *     箱子已经站在目标点上
#   @  玩家            +     玩家站在目标点上
#   .  目标点
const LEVEL := [
	"################",
	"#@$.           #",
	"#  ##########  #",
	"#  #        #  #",
	"#  #        #  #",
	"#  #        #  #",
	"#  #        #  #",
	"#  #        #  #",
	"#  #        #  #",
	"#  ##########  #",
	"#   *          #",
	"################",
]

var cell := Vector2i.ZERO          # 玩家所在格，由解析填进来
var box_cells: Array[Vector2i] = []
var goals: Array[Vector2i] = []

@onready var player := $Player
@onready var box_pool := [$Box1, $Box2]
@onready var win_layer := $WinLayer

func _ready() -> void:
	build_level()

func build_level() -> void:
	# 重开一关只要重新解析一遍，别的都不用动
	parse_level(LEVEL)
	player.position = Vector2(cell) * CELL
	_sync_boxes()
	_refresh()
	queue_redraw()

func parse_level(lines: Array) -> void:
	# 一个字符一个字符地看，看到什么就往对应的数组里塞
	box_cells.clear()
	goals.clear()
	for r in lines.size():
		var row: String = lines[r]
		for c in row.length():
			var ch := row.substr(c, 1)
			var pos := Vector2i(c, r)
			if ch == "@":
				cell = pos
			elif ch == "+":
				cell = pos
				goals.append(pos)
			elif ch == "$":
				box_cells.append(pos)
			elif ch == "*":
				box_cells.append(pos)
				goals.append(pos)
			elif ch == ".":
				goals.append(pos)

func _draw() -> void:
	for r in range(LEVEL.size()):
		var row: String = LEVEL[r]
		for c in range(row.length()):
			var pos := Vector2(c * CELL, r * CELL)
			if row.substr(c, 1) == WALL:
				draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.34, 0.34, 0.46))
			else:
				draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.11, 0.11, 0.15))

	var grid_col := Color(0.22, 0.22, 0.30)
	for c in range(17):
		draw_line(Vector2(c * CELL, 0), Vector2(c * CELL, 12 * CELL), grid_col, 1)
	for r in range(13):
		draw_line(Vector2(0, r * CELL), Vector2(16 * CELL, r * CELL), grid_col, 1)

	for g in goals:
		var p := Vector2(g) * CELL
		draw_rect(Rect2(p + Vector2(8, 8), Vector2(CELL - 16, CELL - 16)), Color(0.35, 0.85, 0.6), false, 2)

	draw_rect(Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)), Color(0.95, 0.85, 0.3), false, 2)

func is_wall(c: Vector2i) -> bool:
	# 墙还是直接从文本里读，越界一律当墙
	if c.y < 0 or c.y >= LEVEL.size():
		return true
	var row: String = LEVEL[c.y]
	if c.x < 0 or c.x >= row.length():
		return true
	return row.substr(c.x, 1) == WALL

func find_box(c: Vector2i) -> int:
	for i in box_cells.size():
		if box_cells[i] == c:
			return i
	return -1

func can_enter(c: Vector2i) -> bool:
	return not is_wall(c) and find_box(c) == -1

func on_goal(c: Vector2i) -> bool:
	for g in goals:
		if g == c:
			return true
	return false

func is_win() -> bool:
	for g in goals:
		if find_box(g) == -1:
			return false
	return true

func _sync_boxes() -> void:
	# 箱子精灵是事先摆好的几个，按解析结果分配；多余的藏起来
	for i in box_pool.size():
		if i < box_cells.size():
			box_pool[i].visible = true
			box_pool[i].position = Vector2(box_cells[i]) * CELL
		else:
			box_pool[i].visible = false

func _refresh() -> void:
	for i in box_pool.size():
		if i >= box_cells.size():
			continue
		box_pool[i].modulate = Color(0.6, 1.0, 0.75) if on_goal(box_cells[i]) else Color(1, 1, 1)
	win_layer.visible = is_win()

func _dir_from_event(event) -> Vector2i:
	if event.is_action_pressed("move_up"):
		return Vector2i(0, -1)
	if event.is_action_pressed("move_down"):
		return Vector2i(0, 1)
	if event.is_action_pressed("move_left"):
		return Vector2i(-1, 0)
	if event.is_action_pressed("move_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _unhandled_input(event) -> void:
	if event.is_action_pressed("restart"):
		build_level()
		return

	var dir := _dir_from_event(event)
	if dir == Vector2i.ZERO:
		return

	var target := cell + dir
	if is_wall(target):
		return

	var box_index := find_box(target)
	var beyond := Vector2i.ZERO
	if box_index != -1:
		beyond = target + dir
		if not can_enter(beyond):
			return

	if box_index != -1:
		box_cells[box_index] = beyond

	cell = target

	var tween := create_tween()
	tween.tween_property(player, "position", Vector2(cell) * CELL, 0.12)
	if box_index != -1:
		tween.parallel().tween_property(box_pool[box_index], "position", Vector2(box_cells[box_index]) * CELL, 0.12)
	_refresh()
	queue_redraw()
