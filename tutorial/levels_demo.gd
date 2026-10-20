extends Node2D

# 教学演示：多关卡——把三份地图装进一个数组，通关能切下一关
# 第 12 篇我们已经能把一份文本解析成关卡了，
# 这一篇只加一件事：文本从一份变成一组，并且能在它们之间跳

const CELL := 32
const WALL := "#"

# 多关卡没什么神秘的，就是个「数组的数组」：
# LEVELS[0] 是第一关那叠文本，LEVELS[1] 是第二关……
const LEVELS := [
	[
		"################",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"#    @$.       #",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"################",
	],
	[
		"################",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"#  .  $ @ $  . #",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"################",
	],
	[
		"################",
		"#              #",
		"#   .     .    #",
		"#              #",
		"#   $     $    #",
		"#              #",
		"#      @       #",
		"#              #",
		"#              #",
		"#              #",
		"#              #",
		"################",
	],
]

var level_index := 0                 # 当前是第几关（从 0 开始数）
var cell := Vector2i.ZERO            # 玩家所在格，由解析填进来
var box_cells: Array[Vector2i] = []
var goals: Array[Vector2i] = []
var history: Array = []              # 撤销用的存档
var move_tween: Tween = null         # 正在跑的移动补间，切关时要掐掉

@onready var player := $Player
@onready var box_pool := [$Box1, $Box2]
@onready var win_layer := $WinLayer
@onready var win_label := $WinLayer/WinLabel

func _ready() -> void:
	load_level(0)

func load_level(i: int) -> void:
	# 换关就调这一个函数，别的都不用操心
	level_index = i

	# 换关第一件事：把上一关留下的东西清干净
	# 箱子坐标和目标点由 parse_level 里的 clear() 负责，
	# 但撤销记录是这一篇才有的，得自己清
	history.clear()
	# 上一关的补间要是还在跑，它会把新关卡的精灵拽回老位置，先掐掉
	if move_tween != null:
		move_tween.kill()

	parse_level(LEVELS[i])
	player.position = Vector2(cell) * CELL
	_sync_boxes()
	_refresh()
	queue_redraw()

func next_level() -> void:
	# 已经是最后一关就没得跳了
	if level_index + 1 >= LEVELS.size():
		return
	load_level(level_index + 1)

func parse_level(lines: Array) -> void:
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
	var lines: Array = LEVELS[level_index]
	for r in lines.size():
		var row: String = lines[r]
		for c in row.length():
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

	# 左上角标一句当前是第几关，切关时一眼能看出来
	var f := ThemeDB.fallback_font
	var tip := "第 %d / %d 关　可撤销 %d 步" % [level_index + 1, LEVELS.size(), history.size()]
	draw_string(f, Vector2(8, 20), tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.8, 0.9))

func is_wall(c: Vector2i) -> bool:
	var lines: Array = LEVELS[level_index]
	if c.y < 0 or c.y >= lines.size():
		return true
	var row: String = lines[c.y]
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
	# 不同关箱子数不一样，用的显出来，多余的藏起来
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

	if is_win():
		# 最后一关跟前面几关说的话不一样
		if level_index == LEVELS.size() - 1:
			win_label.text = "全部 %d 关通关！" % LEVELS.size()
		else:
			win_label.text = "第 %d 关通关！按 N 进下一关" % (level_index + 1)
	win_layer.visible = is_win()

func _push_history() -> void:
	history.push_back({
		"cell": cell,
		"boxes": box_cells.duplicate(),
	})

func undo() -> void:
	if history.is_empty():
		return
	var last: Dictionary = history.pop_back()
	cell = last["cell"]
	box_cells.assign(last["boxes"])
	player.position = Vector2(cell) * CELL
	_sync_boxes()
	_refresh()
	queue_redraw()

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
	if event.is_action_pressed("next"):
		next_level()
		return
	if event.is_action_pressed("restart"):
		load_level(level_index)
		return
	if event.is_action_pressed("undo"):
		undo()
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

	_push_history()

	if box_index != -1:
		box_cells[box_index] = beyond

	cell = target

	move_tween = create_tween()
	move_tween.tween_property(player, "position", Vector2(cell) * CELL, 0.12)
	if box_index != -1:
		move_tween.parallel().tween_property(box_pool[box_index], "position", Vector2(box_cells[box_index]) * CELL, 0.12)
	_refresh()
	queue_redraw()
