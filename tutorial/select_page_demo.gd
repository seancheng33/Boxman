extends Control

# 教学演示：选关界面（下）——分页 + 实时预览
# 第 15 篇把按钮批量造出来了，这一篇解决两个新问题：
# 1. 关卡多了一页放不下：分页
# 2. 选关前想先看一眼这关长什么样：实时预览

const LEVEL_COUNT := 7
const PAGE_SIZE := 6              # 一页 6 关，7 关正好拆成两页
const SAVE_PATH := "user://progress.cfg"
const DEFAULT_UNLOCKED := 5

# 七关地图，第 6、7 关默认锁着（跟第 14 篇同一套数据）
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

var unlocked := DEFAULT_UNLOCKED
var page := 0
var selected := 0

@onready var grid := $Grid
@onready var prev_btn := $PrevBtn
@onready var next_btn := $NextBtn
@onready var page_label := $PageLabel
@onready var tip_label := $TipLabel
@onready var status_label := $StatusLabel

func _ready() -> void:
	load_progress()
	build_grid()
	refresh()
	_show_preview(selected)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		unlocked = DEFAULT_UNLOCKED
		return
	unlocked = mini(cfg.get_value("progress", "unlocked", DEFAULT_UNLOCKED), LEVEL_COUNT)

func build_grid() -> void:
	for i in LEVEL_COUNT:
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(72, 48)
		btn.add_theme_font_size_override("font_size", 20)
		# 焦点一到按钮上就更新预览——键盘挪焦点也能联动
		btn.focus_entered.connect(_on_focus_btn.bind(i))
		btn.pressed.connect(_on_level_pressed.bind(i))
		grid.add_child(btn)

func page_count() -> int:
	return int(ceil(float(LEVEL_COUNT) / PAGE_SIZE))

func refresh() -> void:
	var start := page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, LEVEL_COUNT)
	for i in LEVEL_COUNT:
		var btn: Button = grid.get_child(i)
		btn.disabled = i >= unlocked
		# 灰掉的按钮顺手把焦点也摘掉：Tab 别停在没用的按钮上
		btn.focus_mode = Control.FOCUS_NONE if btn.disabled else Control.FOCUS_ALL
		btn.visible = i >= start and i < end
	page_label.text = "第 %d / %d 页" % [page + 1, page_count()]
	prev_btn.disabled = page <= 0
	next_btn.disabled = page >= page_count() - 1
	tip_label.text = "已解锁 %d / %d 关" % [unlocked, LEVEL_COUNT]
	# 焦点尽量留在当前选中项上；选中项不在本页，就落回本页第一关
	if selected < start or selected >= end:
		selected = start
	if selected < grid.get_child_count():
		var cur: Button = grid.get_child(selected)
		if not cur.disabled:
			cur.grab_focus()

func _show_preview(i: int) -> void:
	selected = i
	var lines: Array = LEVELS[i]
	var boxes := 0
	var goals := 0
	for row in lines:
		var text: String = row
		for c in text.length():
			var ch := text.substr(c, 1)
			if ch == "$" or ch == "*":
				boxes += 1
			if ch == "." or ch == "*":
				goals += 1
	status_label.text = "第 %d 关预览：%d 个箱子，%d 个目标点" % [i + 1, boxes, goals]
	queue_redraw()

func _on_focus_btn(i: int) -> void:
	_show_preview(i)

func _on_level_pressed(i: int) -> void:
	status_label.text = "进入第 %d 关——这里就是加载关卡的地方" % (i + 1)

func _on_prev() -> void:
	if page > 0:
		page -= 1
		refresh()
		_show_preview(selected)

func _on_next() -> void:
	if page < page_count() - 1:
		page += 1
		refresh()
		_show_preview(selected)

func _unhandled_input(event) -> void:
	# Esc 回主菜单：场景切换是双向的，进得来也要回得去
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://main_menu.tscn")
		return
	if event.is_action_pressed("next"):
		unlocked = mini(unlocked + 1, LEVEL_COUNT)
		save_progress()
		refresh()
		return
	if event.is_action_pressed("restart"):
		unlocked = DEFAULT_UNLOCKED
		save_progress()
		refresh()
		return

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)

func _draw() -> void:
	# 右侧预览区：边框 + 选中关卡的缩略地图
	draw_rect(Rect2(300, 56, 196, 148), Color(0.08, 0.08, 0.12), false, 2)
	var lines: Array = LEVELS[selected]
	var first: String = lines[0]
	var cs := 11.0
	var ox := 300.0 + (196.0 - first.length() * cs) / 2.0
	var oy := 56.0 + (148.0 - lines.size() * cs) / 2.0
	for r in lines.size():
		var row: String = lines[r]
		for c in row.length():
			var ch := row.substr(c, 1)
			var pos := Vector2(ox + c * cs, oy + r * cs)
			if ch == "#":
				draw_rect(Rect2(pos, Vector2(cs, cs)), Color(0.34, 0.34, 0.46))
			elif ch == "$" or ch == "*":
				draw_rect(Rect2(pos + Vector2(2, 2), Vector2(cs - 4, cs - 4)), Color(0.85, 0.65, 0.3))
			elif ch == "." or ch == "*":
				draw_rect(Rect2(pos + Vector2(2, 2), Vector2(cs - 4, cs - 4)), Color(0.35, 0.85, 0.6), false, 1)
			elif ch == "@" or ch == "+":
				draw_rect(Rect2(pos + Vector2(1, 1), Vector2(cs - 2, cs - 2)), Color(0.95, 0.85, 0.3), false, 2)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(304, 220), "预览：第 %d 关" % (selected + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.75, 0.8, 0.9))
