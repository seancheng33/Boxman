extends Node2D

# 教学演示：存档与解锁——把通关进度写进文件
# 第 13 篇能一关一关往下推了，这一篇只加一件事：
# 关掉游戏再打开，通到第几关得记得住

const CELL := 32
const WALL := "#"

const SAVE_PATH := "user://progress.cfg"
const DEFAULT_UNLOCKED := 5          # 第一次玩，先开放 5 关

# 七关，第 6、7 关默认锁着，得通关第 5 关才放出来
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
	[
		"################",
		"#              #",
		"#              #",
		"#     .        #",
		"#     $        #",
		"#        @     #",
		"#     $        #",
		"#     .        #",
		"#              #",
		"#              #",
		"#              #",
		"################",
	],
	[
		"################",
		"#              #",
		"#              #",
		"#   .   .   .  #",
		"#   $   $   $  #",
		"#      @       #",
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
		"#  .           #",
		"#  $           #",
		"#     @        #",
		"#        $  .  #",
		"#              #",
		"#     $   .    #",
		"#              #",
		"#              #",
		"################",
	],
	[
		"################",
		"#      #       #",
		"#  .   #  .    #",
		"#  $   #  $    #",
		"#      #       #",
		"#   ######     #",
		"#              #",
		"#     @        #",
		"#              #",
		"#     $   .    #",
		"#              #",
		"################",
	],
]

var level_index := 0
var unlocked := DEFAULT_UNLOCKED       # 当前能玩到第几关
var cell := Vector2i.ZERO
var box_cells: Array[Vector2i] = []
var goals: Array[Vector2i] = []
var history: Array = []
var move_tween: Tween = null

@onready var player := $Player
@onready var box_pool := [$Box1, $Box2, $Box3]
@onready var win_layer := $WinLayer
@onready var win_label := $WinLayer/WinLabel

func _ready() -> void:
	print(ProjectSettings.globalize_path("user://"))
	load_progress()
	load_level(0)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	# 第一次跑，这个文件根本不存在，load 会返回错误码
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		unlocked = DEFAULT_UNLOCKED
		print("没找到存档（错误码 %d），用默认值 %d 关" % [err, DEFAULT_UNLOCKED])
		return
	# get_value 第三个参数是兜底值：文件里没这一项时就用它
	unlocked = cfg.get_value("progress", "unlocked", DEFAULT_UNLOCKED)
	# 万一以后删了关卡，别让解锁数超过总关卡数
	unlocked = mini(unlocked, LEVELS.size())
	print("读到存档：已解锁 %d 关" % unlocked)

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	var err := cfg.save(SAVE_PATH)
	print("写存档：unlocked = %d（错误码 %d，0 就是成功）" % [unlocked, err])

func load_level(i: int) -> void:
	# 没解锁的关卡不放行
	if i >= unlocked:
		return
	level_index = i
	history.clear()
	if move_tween != null:
		move_tween.kill()
	parse_level(LEVELS[i])
	player.position = Vector2(cell) * CELL
	_sync_boxes()
	_refresh()
	queue_redraw()

func next_level() -> void:
	if level_index + 1 >= unlocked:
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

	var f := ThemeDB.fallback_font
	var tip := "第 %d / %d 关　已解锁 %d 关" % [level_index + 1, LEVELS.size(), unlocked]
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
		_unlock_next()
		if level_index == LEVELS.size() - 1:
			win_label.text = "全部 %d 关通关！" % LEVELS.size()
		elif level_index + 1 >= unlocked:
			win_label.text = "第 %d 关通关！这是最后一关了" % (level_index + 1)
		else:
			win_label.text = "第 %d 关通关！按 N 进下一关（已解锁 %d 关）" % [level_index + 1, unlocked]
	win_layer.visible = is_win()

func _unlock_next() -> void:
	# 通关第 N 关（level_index 从 0 数），就把第 N+2 关放开
	var want := mini(level_index + 2, LEVELS.size())
	if want > unlocked:
		unlocked = want
		save_progress()

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
