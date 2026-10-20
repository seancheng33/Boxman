extends Node2D

# 教学演示：用 InputMap 配置方向键 + WASD，按一下玩家走一格
# 这一篇只解决一件事：让键盘能跟游戏说话

const CELL := 32
const COLS := 16
const ROWS := 12

var cell := Vector2i(3, 2)   # 玩家当前所在的格子

@onready var player := $Player

func _draw() -> void:
	var w := COLS * CELL
	var h := ROWS * CELL
	var f := ThemeDB.fallback_font

	# 先铺一块底色，网格才看得清
	draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.12, 0.17))

	# 网格线
	var line_col := Color(0.33, 0.33, 0.45)
	for c in range(COLS + 1):
		var x := float(c * CELL)
		draw_line(Vector2(x, 0), Vector2(x, h), line_col, 1)
	for r in range(ROWS + 1):
		var y := float(r * CELL)
		draw_line(Vector2(0, y), Vector2(w, y), line_col, 1)

	# 高亮玩家当前所在的格子（黄框），走一格它就挪一格
	var ppos := Vector2(cell) * CELL
	draw_rect(Rect2(ppos, Vector2(CELL, CELL)), Color(0.95, 0.85, 0.3), false, 2)

func _ready() -> void:
	player.position = Vector2(cell) * CELL
	queue_redraw()

func _unhandled_input(event) -> void:
	# event.is_action_pressed 只在「刚按下那一帧」返回 true
	# 这样就天然防住长按连发，按一下只走一格
	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"):
		dir = Vector2i(1, 0)

	if dir != Vector2i.ZERO:
		cell += dir
		# 用 tween 让移动平滑一点，硬跳看着像闪现
		var tween := create_tween()
		tween.tween_property(player, "position", Vector2(cell) * CELL, 0.12)
		queue_redraw()
