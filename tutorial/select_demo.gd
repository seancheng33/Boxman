extends Control

# 教学演示：选关界面（上）——用代码批量造按钮
# 第 14 篇把进度存进文件了，这一篇只加一件事：
# 一进游戏就能看到所有关卡，点哪关进哪关
#
# 这一篇的重点不是"画得好看"，是"别再手摆七个按钮"：
# 关卡有多少个，按钮就造多少个，一个 for 循环搞定

const LEVEL_COUNT := 7
const SAVE_PATH := "user://progress.cfg"
const DEFAULT_UNLOCKED := 5

var unlocked := DEFAULT_UNLOCKED
var selected := 0                     # 键盘/鼠标选中的是第几关（从 0 数）

@onready var grid := $Grid
@onready var tip_label := $TipLabel
@onready var status_label := $StatusLabel

func _ready() -> void:
	load_progress()
	build_grid()
	refresh()

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
		# bind 把 "这是第几个" 一起塞进信号，回调里才知道按下的是哪关
		btn.pressed.connect(_on_level_pressed.bind(i))
		grid.add_child(btn)

func refresh() -> void:
	for i in grid.get_child_count():
		var btn: Button = grid.get_child(i)
		btn.disabled = i >= unlocked
	tip_label.text = "已解锁 %d / %d 关　（N 解锁下一关，R 清回 %d 关）" % [unlocked, LEVEL_COUNT, DEFAULT_UNLOCKED]
	# 把焦点挪到当前选中项上，方向键挪焦点、空格确认，Godot 的 UI 全给你包了
	if selected < grid.get_child_count():
		var cur: Button = grid.get_child(selected)
		if not cur.disabled:
			cur.grab_focus()

func _on_level_pressed(i: int) -> void:
	selected = i
	refresh()
	status_label.text = "选中第 %d 关——这里就是加载关卡的地方" % (i + 1)

func _unhandled_input(event) -> void:
	if event.is_action_pressed("next"):
		unlocked = mini(unlocked + 1, LEVEL_COUNT)
		save_progress()
		refresh()
		status_label.text = "解锁到第 %d 关，按钮跟着亮了" % unlocked
		return
	if event.is_action_pressed("restart"):
		unlocked = DEFAULT_UNLOCKED
		save_progress()
		refresh()
		status_label.text = "进度清回 %d 关，按钮跟着灰了" % DEFAULT_UNLOCKED
		return

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)
