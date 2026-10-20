extends Control

# 教学演示：视觉打磨——调色板 + 程序化锁图标
# 功能到第 16 篇就齐了，画面还是灰扑扑的。
# 这一篇不改任何逻辑，只做两件事：
# 1. 把散在各处的颜色收进一个调色板，一处改、全局变
# 2. 没解锁的按钮挂一把程序化生成的锁——不请美术，代码逐像素画

const LEVEL_COUNT := 7
const PAGE_SIZE := 6
const SAVE_PATH := "user://progress.cfg"
const DEFAULT_UNLOCKED := 5

# 调色板：全游戏的颜色只在这一个地方出现
const PAL := {
	"bg": Color(0.09, 0.09, 0.13),
	"panel": Color(0.14, 0.14, 0.19),
	"wall": Color(0.38, 0.38, 0.55),
	"floor": Color(0.12, 0.12, 0.17),
	"goal": Color(0.35, 0.85, 0.6),
	"player": Color(0.95, 0.8, 0.3),
	"box": Color(0.85, 0.62, 0.3),
	"box_on_goal": Color(0.5, 0.95, 0.65),
	"text": Color(0.78, 0.82, 0.92),
	"text_dim": Color(0.5, 0.53, 0.62),
	"lock": Color(0.9, 0.32, 0.32),
}

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
	apply_theme()
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
		btn.focus_entered.connect(_on_focus_btn.bind(i))
		btn.pressed.connect(_on_level_pressed.bind(i))
		grid.add_child(btn)

func apply_theme() -> void:
	# 颜色只从调色板里取，改主题就是改 PAL 一个字典
	get_node("TitleLabel").add_theme_color_override("font_color", PAL.text)
	for i in LEVEL_COUNT:
		var btn: Button = grid.get_child(i)
		btn.add_theme_color_override("font_color", PAL.text)
		btn.add_theme_color_override("font_disabled_color", PAL.text_dim)
	prev_btn.add_theme_color_override("font_color", PAL.text)
	next_btn.add_theme_color_override("font_color", PAL.text)
	page_label.add_theme_color_override("font_color", PAL.text_dim)
	tip_label.add_theme_color_override("font_color", PAL.text_dim)
	status_label.add_theme_color_override("font_color", PAL.text)

func make_lock_icon() -> ImageTexture:
	# 12x14 逐像素画一把小红锁：两根竖梁 + 顶横 + 实心锁身 + 透明锁孔
	var img := Image.create(12, 14, false, Image.FORMAT_RGBA8)
	var c: Color = PAL.lock
	for y in range(1, 6):
		img.set_pixel(3, y, c)
		img.set_pixel(8, y, c)
	for x in range(3, 9):
		img.set_pixel(x, 1, c)
	img.fill_rect(Rect2i(2, 6, 8, 7), c)
	img.set_pixel(5, 9, Color(0, 0, 0, 0))
	img.set_pixel(6, 9, Color(0, 0, 0, 0))
	img.set_pixel(5, 10, Color(0, 0, 0, 0))
	img.set_pixel(6, 10, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func page_count() -> int:
	return int(ceil(float(LEVEL_COUNT) / PAGE_SIZE))

func refresh() -> void:
	var start := page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, LEVEL_COUNT)
	for i in LEVEL_COUNT:
		var btn: Button = grid.get_child(i)
		btn.disabled = i >= unlocked
		btn.focus_mode = Control.FOCUS_NONE if btn.disabled else Control.FOCUS_ALL
		btn.visible = i >= start and i < end
		_update_lock(btn, i)
	page_label.text = "第 %d / %d 页" % [page + 1, page_count()]
	prev_btn.disabled = page <= 0
	next_btn.disabled = page >= page_count() - 1
	tip_label.text = "已解锁 %d / %d 关" % [unlocked, LEVEL_COUNT]
	if selected < start or selected >= end:
		selected = start
	if selected < grid.get_child_count():
		var cur: Button = grid.get_child(selected)
		if not cur.disabled:
			cur.grab_focus()

func _update_lock(btn: Button, i: int) -> void:
	# 锁图标挂按钮右上角：已经挂过的不重复挂
	var icon := btn.get_node_or_null("Lock") as TextureRect
	if i < unlocked:
		if icon != null:
			icon.queue_free()
		return
	if icon == null:
		icon = TextureRect.new()
		icon.name = "Lock"
		icon.texture = make_lock_icon()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 锚点定在按钮右上角，往外挑一点
		icon.anchor_left = 1.0
		icon.anchor_right = 1.0
		icon.offset_left = -14.0
		icon.offset_right = -2.0
		icon.offset_top = -8.0
		icon.offset_bottom = 6.0
		btn.add_child(icon)

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
	# 背景：整屏先铺底色
	draw_rect(Rect2(Vector2.ZERO, size), PAL.bg)
	# 右侧预览区：面板底 + 边框 + 缩略地图，颜色全部取自调色板
	draw_rect(Rect2(300, 56, 196, 148), PAL.panel)
	draw_rect(Rect2(300, 56, 196, 148), PAL.wall, false, 2)
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
				draw_rect(Rect2(pos, Vector2(cs, cs)), PAL.wall)
			elif ch == "$" or ch == "*":
				var col: Color = PAL.box_on_goal if ch == "*" else PAL.box
				draw_rect(Rect2(pos + Vector2(2, 2), Vector2(cs - 4, cs - 4)), col)
			elif ch == "." or ch == "*":
				draw_rect(Rect2(pos + Vector2(2, 2), Vector2(cs - 4, cs - 4)), PAL.goal, false, 1)
			elif ch == "@" or ch == "+":
				draw_rect(Rect2(pos + Vector2(1, 1), Vector2(cs - 2, cs - 2)), PAL.player, false, 2)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(304, 220), "预览：第 %d 关" % (selected + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PAL.text)
