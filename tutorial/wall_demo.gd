extends Node2D

# 教学演示：用字符串数组当地图，走之前先问一句「那格能进吗」
# 这一篇解决两件事：撞墙别动，还有别走出数组的边

const CELL := 32
const COLS := 16
const ROWS := 12
const WALL := "#"      # 墙
const FLOOR := "."     # 地板

# 地图就是几行字，看得见摸得着，改起来也快
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

var cell := Vector2i(1, 1)   # 玩家的起点，左上角那条走廊

@onready var player := $Player

func _draw() -> void:
	for r in range(ROWS):
		var row: String = MAP[r]
		for c in range(COLS):
			var pos := Vector2(c * CELL, r * CELL)
			if row.substr(c, 1) == WALL:
				# 墙：实心的深色方块
				draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.34, 0.34, 0.46))
			else:
				# 地板：FLOOR 那格，画得更暗一点
				draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.11, 0.11, 0.15))

	# 淡淡的分隔线，格子边界看得清
	var grid_col := Color(0.22, 0.22, 0.30)
	for c in range(COLS + 1):
		draw_line(Vector2(c * CELL, 0), Vector2(c * CELL, ROWS * CELL), grid_col, 1)
	for r in range(ROWS + 1):
		draw_line(Vector2(0, r * CELL), Vector2(COLS * CELL, r * CELL), grid_col, 1)

	# 高亮玩家所在格
	draw_rect(Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)), Color(0.95, 0.85, 0.3), false, 2)

func is_wall(c: Vector2i) -> bool:
	# 越界一律当墙，边界判定就这么顺手带上了
	if c.y < 0 or c.y >= MAP.size():
		return true
	var row: String = MAP[c.y]
	if c.x < 0 or c.x >= row.length():
		return true
	return row.substr(c.x, 1) == WALL

func _ready() -> void:
	player.position = Vector2(cell) * CELL
	queue_redraw()

func _unhandled_input(event) -> void:
	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"):
		dir = Vector2i(1, 0)

	if dir == Vector2i.ZERO:
		return

	var target := cell + dir
	if is_wall(target):
		# 撞墙：这一步作废，cell 不动，人也不动
		return

	cell = target
	var tween := create_tween()
	tween.tween_property(player, "position", Vector2(cell) * CELL, 0.12)
	queue_redraw()
