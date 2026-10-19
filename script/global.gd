extends Node

# ---------- 多语言 ----------
# lang: "zh" / "en"，持久化在 user://settings.cfg
const LANG_CFG_PATH = "user://settings.cfg"
var lang: String = "zh"

# ---------- 关卡解锁进度（游戏状态，持久化在 user://progress.cfg） ----------
# 默认解锁前 5 关（0 基索引 < unlocked_count 即可选），通关第 N 关自动解锁第 N+1 关；
# 同时记录已通关关卡集合与上次游玩的关卡，选关界面据此还原游戏状态。
const PROGRESS_CFG_PATH = "user://progress.cfg"
const DEFAULT_UNLOCKED = 5
var unlocked_count: int = DEFAULT_UNLOCKED
# 已通关关卡索引集合（0 基）
var cleared_levels: Dictionary = {}
# 上次游玩的关卡索引（-1 表示尚无记录），选关界面打开时定位到该关所在页
var last_level_index: int = -1

const TEXTS = {
	"zh": {
		"title.new": "新 的 游 戏",
		"title.select": "游 戏 选 关",
		"title.about": "关    于",
		"title.exit": "退 出 游 戏",
		"title.subtitle": "BOXMAN · 经典推箱子 237 关",
		"menu.prev": "上一关",
		"menu.next": "下一关",
		"menu.reset": "重置本关",
		"menu.back": "返回主菜单",
		"menu.current": "当前关卡：第 %d 关",
		"win.msg": "恭喜完成本关，是否继续下一关？",
		"win.quit": "返回主菜单",
		"win.next": "进入下一关",
		"win.last": "已是最后一关！",
		"about.text": "游戏介绍：\n\t使用键盘的方向键或【W、A、S、D】字母键控制角色上下左右移动，按【Z】键可撤销上一步操作。\n\t把所有目标点都推上箱子即可过关。游戏采用解锁制：初始开放前 5 关，通关一关自动解锁下一关。\n\t通关后可选下一关或返回主菜单，也可以在游戏中通过「上一关 / 下一关」按钮切换关卡（仅限已解锁的关卡）。\n\t游戏素材下载自免费游戏素材网站：https://kenney.nl/\n\t游戏关卡来自：http://sokoban.cn/ 中的经典关卡，去重后共237关。\n\t关卡和其他的内容将逐步更新。您如果有发现bug或者其他建议，欢迎将建议发送至我的邮箱，aya234@163.com\n\t一个人独立游戏制作不容易，如果您有心，可以捐赠支持一下。",
		"about.back": "返 回",
		"lang.button": "English",
		"page.prev": "上一页",
		"page.next": "下一页",
		"select.page": "第 %d 页 / 共 %d 页",
		"select.enter": "进 入 本 关",
	},
	"en": {
		"title.new": "New Game",
		"title.select": "Select Level",
		"title.about": "About",
		"title.exit": "Quit",
		"title.subtitle": "BOXMAN · 237 Classic Levels",
		"menu.prev": "Prev Level",
		"menu.next": "Next Level",
		"menu.reset": "Restart",
		"menu.back": "Main Menu",
		"menu.current": "Level: %d",
		"win.msg": "Level complete! Continue to the next one?",
		"win.quit": "Main Menu",
		"win.next": "Next Level",
		"win.last": "This is the last level!",
		"about.text": "About:\n\tUse the arrow keys or WASD to move the character; press Z to undo the last move.\n\tPush boxes onto ALL target spots to clear a level. Levels are unlock-based: the first 5 are open from the start, and clearing a level unlocks the next one.\n\tAfter clearing a level you can go to the next one or return to the main menu; you can also switch levels with the Prev/Next buttons in game (unlocked levels only).\n\tArt assets from the free game-asset website: https://kenney.nl/\n\tClassic levels from http://sokoban.cn/, 237 levels after deduplication.\n\tMore levels and content coming soon. Found a bug or have a suggestion? Email me at aya234@163.com\n\tMaking a game all by yourself is not easy - donations are appreciated if you would like to support.",
		"about.back": "Back",
		"lang.button": "中文",
		"page.prev": "Prev Page",
		"page.next": "Next Page",
		"select.page": "Page %d / %d",
		"select.enter": "Play",
	},
}

func _ready():
	# autoload 早于一切场景 _ready，先恢复语言设置
	var cfg = ConfigFile.new()
	if cfg.load(LANG_CFG_PATH) == OK:
		lang = cfg.get_value("ui", "lang", "zh")
		if not TEXTS.has(lang):
			lang = "zh"
	# 恢复游戏状态（首次运行为默认值）
	var progress = ConfigFile.new()
	if progress.load(PROGRESS_CFG_PATH) == OK:
		unlocked_count = max(DEFAULT_UNLOCKED, int(progress.get_value("progress", "unlocked", DEFAULT_UNLOCKED)))
		last_level_index = int(progress.get_value("progress", "last_level", -1))
		cleared_levels.clear()
		for v in progress.get_value("progress", "cleared", []):
			cleared_levels[int(v)] = true

func _save_progress() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked_count)
	cfg.set_value("progress", "last_level", last_level_index)
	var cleared := PoolIntArray()
	for k in cleared_levels:
		cleared.append(int(k))
	cfg.set_value("progress", "cleared", cleared)
	cfg.save(PROGRESS_CFG_PATH)

func is_level_unlocked(index: int) -> bool:
	return index < unlocked_count

func is_level_cleared(index: int) -> bool:
	return cleared_levels.has(index)

# 通关第 index 关（0 基）后调用：记录通关、解锁下一关并持久化
func unlock_up_to(index: int) -> void:
	cleared_levels[index] = true
	# is_level_unlocked(i) = i < unlocked_count，因此要解锁 index+1 需 count ≥ index+2
	var target: int = index + 2
	if target > unlocked_count:
		unlocked_count = target
	_save_progress()

func t(key: String) -> String:
	return TEXTS[lang].get(key, TEXTS["zh"].get(key, key))

func set_lang(value: String) -> void:
	if not TEXTS.has(value):
		return
	lang = value
	var cfg = ConfigFile.new()
	cfg.set_value("ui", "lang", lang)
	cfg.save(LANG_CFG_PATH)

func toggle_lang() -> void:
	set_lang("en" if lang == "zh" else "zh")

# ---------- 分关配色主题 ----------
# 每 20 关一个章节，章节依序轮换 5 套主题，避免视觉疲劳。
# 素材来自 tilesheet.png：
#   箱子正常版 y=0 行、同色暗版 y=64 行（压在目标点上时切换）、目标点括号标记 y=192 行
const THEME_CHAPTER_SIZE = 20
const BOX_THEMES = [
	{"name": "brown", "wall": 0, "box": Rect2(64, 0, 64, 64),  "box_dark": Rect2(64, 64, 64, 64),  "dest": Rect2(64, 192, 64, 64)},
	{"name": "red",   "wall": 1, "box": Rect2(128, 0, 64, 64), "box_dark": Rect2(128, 64, 64, 64), "dest": Rect2(128, 192, 64, 64)},
	{"name": "blue",  "wall": 2, "box": Rect2(192, 0, 64, 64), "box_dark": Rect2(192, 64, 64, 64), "dest": Rect2(192, 192, 64, 64)},
	{"name": "green", "wall": 3, "box": Rect2(256, 0, 64, 64), "box_dark": Rect2(256, 64, 64, 64), "dest": Rect2(256, 192, 64, 64)},
	{"name": "gray",  "wall": 4, "box": Rect2(320, 0, 64, 64), "box_dark": Rect2(320, 64, 64, 64), "dest": Rect2(320, 192, 64, 64)},
]

func get_theme_for_level(index: int) -> Dictionary:
	var chapter: int = int(index / float(THEME_CHAPTER_SIZE))
	return BOX_THEMES[chapter % BOX_THEMES.size()]

# ---------- 方向与关卡 ----------

var directions = {
	"ui_up":Vector2.UP,
	"ui_down":Vector2.DOWN,
	"ui_left":Vector2.LEFT,
	"ui_right":Vector2.RIGHT,
}

const DISTANCE = 64
const LEVEL_DIR = "res://levels_txt/"
const LEVEL_SCENE = "res://scene/LevelTemplate.tscn"

# 关卡列表缓存：扫描结果过滤 Level*.txt 并排序，运行期不会变化
var _level_list: Array = []
# 当前关卡索引（0 基），由 goto_level 维护
var current_level_index: int = 0

func check_finish(destinations):
	var finish_num = 0
	for destination in destinations:
		if destination.is_active:
			finish_num += 1
	return finish_num == destinations.size()

func get_level_list() -> Array:
	if _level_list.empty():
		var dir = Directory.new()
		if dir.open(LEVEL_DIR) == OK:
			dir.list_dir_begin()
			var filename = dir.get_next()
			while filename != "":
				if not dir.current_is_dir() and filename.begins_with("Level") and filename.ends_with(".txt"):
					_level_list.append(LEVEL_DIR + filename)
				filename = dir.get_next()
			dir.list_dir_end()
		_level_list.sort()
	return _level_list

func get_current_level_index() -> int:
	return current_level_index

func goto_level(index: int) -> void:
	var list = get_level_list()
	if index >= 0 and index < list.size():
		current_level_index = index
		last_level_index = index
		_save_progress()
		get_tree().change_scene(LEVEL_SCENE)

# 关卡显示编号（1 基整数），文案层负责拼装 "第 N 关" / "Level N"
func get_level_display_number(path: String) -> int:
	var base := path.get_file().get_basename()
	if base.begins_with("Level") and base.length() > 5 and base.substr(5).is_valid_integer():
		return int(base.substr(5))
	return current_level_index + 1

# 解析标准 sokoban ASCII 关卡文件（首行 "; origin=(x,y)" 为网格原点）
# 返回 {walls: PoolVector2Array, dests: PoolVector2Array, boxes: PoolVector2Array, player: Vector2}
# 坐标为真实网格坐标（已加 origin），世界像素 = 网格 * 64
func load_level_data(path: String) -> Dictionary:
	var f = File.new()
	if f.open(path, File.READ) != OK:
		push_error("无法打开关卡文件: " + path)
		return {}
	var origin := Vector2.ZERO
	var rows: Array = []
	while not f.eof_reached():
		var line: String = f.get_line()
		if line.begins_with(";"):
			var s: String = line.substr(line.find("(") + 1)
			s = s.substr(0, s.length() - 1)
			var parts = s.split(",")
			origin = Vector2(int(parts[0]), int(parts[1]))
		else:
			rows.append(line)
	f.close()
	# 去掉文件尾部空行
	while rows.size() > 0 and String(rows[rows.size() - 1]).strip_edges() == "":
		rows.pop_back()

	var walls := PoolVector2Array()
	var dests := PoolVector2Array()
	var boxes := PoolVector2Array()
	var player := Vector2(-9999, -9999)
	for j in rows.size():
		var row: String = rows[j]
		for i in row.length():
			var cell := Vector2(origin.x + i, origin.y + j)
			var ch: String = row[i]
			if ch == "#":
				walls.append(cell)
			elif ch == ".":
				dests.append(cell)
			elif ch == "$":
				boxes.append(cell)
			elif ch == "*":
				boxes.append(cell)
				dests.append(cell)
			elif ch == "@":
				player = cell
			elif ch == "+":
				player = cell
				dests.append(cell)
	if player.x < -9000:
		push_error("关卡缺少玩家: " + path)
		return {}
	return {"walls": walls, "dests": dests, "boxes": boxes, "player": player}
