extends Node2D

# 教学演示：推箱子——走之前要看两格，不是一格
# 第 08 篇的撞墙判定还在，这一篇只往上加一件事：
# 人要去的那格要是蹲着个箱子，得连箱子的落点一起判

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
	Vector2i(2, 1),   # 箱子 A，紧挨着玩家
	Vector2i(4, 1),   # 箱子 B，挡在 A 后面
]

@onready var player := $Player
@onready var boxes := [$BoxA, $BoxB]

func _ready() -> void:
	player.position = Vector2(cell) * CELL
	_sync_boxes()
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

	# 玩家所在格套个黄框
	draw_rect(Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)), Color(0.95, 0.85, 0.3), false, 2)

func is_wall(c: Vector2i) -> bool:
	# 越界一律当墙，边界判定顺手就带上了
	if c.y < 0 or c.y >= MAP.size():
		return true
	var row: String = MAP[c.y]
	if c.x < 0 or c.x >= row.length():
		return true
	return row.substr(c.x, 1) == WALL

func find_box(c: Vector2i) -> int:
	# 这格有箱子吗？有就返回它在数组里的下标，没有返回 -1
	# 注意这里返回的是下标而不是 true/false：
	# 后面真要挪箱子时，不用再找第二遍
	for i in box_cells.size():
		if box_cells[i] == c:
			return i
	return -1

func can_enter(c: Vector2i) -> bool:
	# 能不能进 = 不是墙，而且没蹲着箱子
	return not is_wall(c) and find_box(c) == -1

func _sync_boxes() -> void:
	# 数据改完，把精灵的位置一次性同步过去
	for i in boxes.size():
		boxes[i].position = Vector2(box_cells[i]) * CELL

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
		return                      # 撞墙，这步作废

	var box_index := find_box(target)
	if box_index != -1:
		# 前面蹲着箱子，那就要多看一格：箱子要去哪里
		var beyond := target + dir
		if not can_enter(beyond):
			return                  # 箱子后面进不去，人和箱子都别动
		box_cells[box_index] = beyond

	cell = target

	var tween := create_tween()
	tween.tween_property(player, "position", Vector2(cell) * CELL, 0.12)
	if box_index != -1:
		# parallel() 让箱子和人同时动，不加的话得等前一个补间跑完
		tween.parallel().tween_property(boxes[box_index], "position", Vector2(box_cells[box_index]) * CELL, 0.12)
	queue_redraw()
