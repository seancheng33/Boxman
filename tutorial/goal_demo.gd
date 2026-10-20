extends Node2D

# 教学演示：给箱子找几个「家」——目标点与胜利判定
# 这一篇只加两件事：目标点怎么表示，以及什么时候算赢

const CELL := 32
const COLS := 16
const ROWS := 12
const WALL := "#"
const FLOOR := "."

const MAP := [
	"################",
	"#..............#",
	"#..##########..#",
	"#..#........#..#",
	"#..#........#..#",
	"#..#........#..#",
	"#..#........#..#",
	"#..#........#..#",
	"#..#........#..#",
	"#..##########..#",
	"#..............#",
	"################",
]

var cell := Vector2i(1, 1)        # 玩家所在格
var box_cells: Array[Vector2i] = [
	Vector2i(2, 1),               # 箱子 B，推一格就到目标
	Vector2i(6, 1),               # 箱子 A，一开始就摆在目标上
]
var goals: Array[Vector2i] = [
	Vector2i(3, 1),
	Vector2i(6, 1),
]

@onready var player := $Player
@onready var boxes := [$BoxB, $BoxA]
@onready var win_layer := $WinLayer

func _ready() -> void:
	player.position = Vector2(cell) * CELL
	_sync_box_positions()
	_refresh()
	queue_redraw()

func _draw() -> void:
	for r in range(ROWS):
		var row: String = MAP[r]
		for c in range(COLS):
			var pos := Vector2(c * CELL, r * CELL)
			if row.substr(c, 1) == WALL:
				draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.34, 0.34, 0.46))
			else:
				draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.11, 0.11, 0.15))

	var grid_col := Color(0.22, 0.22, 0.30)
	for c in range(COLS + 1):
		draw_line(Vector2(c * CELL, 0), Vector2(c * CELL, ROWS * CELL), grid_col, 1)
	for r in range(ROWS + 1):
		draw_line(Vector2(0, r * CELL), Vector2(COLS * CELL, r * CELL), grid_col, 1)

	# 目标点：画成一个小方框，箱子推进来就把它填上
	for g in goals:
		var p := Vector2(g) * CELL
		draw_rect(Rect2(p + Vector2(8, 8), Vector2(CELL - 16, CELL - 16)), Color(0.35, 0.85, 0.6), false, 2)

	draw_rect(Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)), Color(0.95, 0.85, 0.3), false, 2)

func is_wall(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= MAP.size():
		return true
	var row: String = MAP[c.y]
	if c.x < 0 or c.x >= row.length():
		return true
	return row.substr(c.x, 1) == WALL

func find_box(c: Vector2i) -> int:
	# 这格有箱子吗？有就返回下标，没有返回 -1
	for i in box_cells.size():
		if box_cells[i] == c:
			return i
	return -1

func can_enter(c: Vector2i) -> bool:
	return not is_wall(c) and find_box(c) == -1

func on_goal(c: Vector2i) -> bool:
	# 这一格是不是目标点
	for g in goals:
		if g == c:
			return true
	return false

func is_win() -> bool:
	# 每个目标点上都得蹲着一个箱子，少一个都不算
	for g in goals:
		if find_box(g) == -1:
			return false
	return true

func _sync_box_positions() -> void:
	# 只在初始化时调一次，之后箱子位置交给 tween
	for i in boxes.size():
		boxes[i].position = Vector2(box_cells[i]) * CELL

func _refresh() -> void:
	# 数据变了，把「外观」刷一遍：箱子颜色 + 胜利面板
	for i in boxes.size():
		boxes[i].modulate = Color(0.6, 1.0, 0.75) if on_goal(box_cells[i]) else Color(1, 1, 1)
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
	var dir := _dir_from_event(event)
	if dir == Vector2i.ZERO:
		return

	var target := cell + dir
	if is_wall(target):
		return

	var box_index := find_box(target)
	if box_index != -1:
		var beyond := target + dir
		if not can_enter(beyond):
			return
		box_cells[box_index] = beyond

	cell = target

	var tween := create_tween()
	tween.tween_property(player, "position", Vector2(cell) * CELL, 0.12)
	if box_index != -1:
		tween.parallel().tween_property(boxes[box_index], "position", Vector2(box_cells[box_index]) * CELL, 0.12)
	# 每走一步都重新问一次「赢了吗」——推离目标点也得能取消
	_refresh()
	queue_redraw()
