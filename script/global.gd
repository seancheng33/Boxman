extends Node

# ---------- 多语言 ----------
# lang: "zh" / "en"，持久化在 user://settings.cfg
const LANG_CFG_PATH = "user://settings.cfg"
var lang: String = "zh"

# ---------- 关卡解锁进度 ----------
# 默认解锁前 5 关（0 基索引 < unlocked_count 即可选），通关第 N 关自动解锁第 N+1 关
const PROGRESS_CFG_PATH = "user://progress.cfg"
const DEFAULT_UNLOCKED = 5
var unlocked_count: int = DEFAULT_UNLOCKED

const TEXTS = {
	"zh": {
		"title.new": "新 的 游 戏",
		"title.select": "游 戏 选 关",
		"title.about": "关    于",
		"title.exit": "退 出 游 戏",
		"menu.prev": "上一关",
		"menu.next": "下一关",
		"menu.reset": "重置本关",
		"menu.back": "返回主菜单",
		"menu.current": "当前关卡： %s",
		"win.msg": "恭喜完成本关，是否继续下一关？",
		"win.quit": "返回主菜单",
		"win.next": "进入下一关",
		"win.last": "已是最后一关！",
		"about.text": "游戏介绍：\n\t使用键盘的方向键或者【A、S、D、W】字母键控制角色上下左右移动。\n\t推动箱子到目的位置，游戏完成后可选下一关或者返回主菜单界面，也可以在游戏中通过上一关和下一关按键选择游戏的关卡。\n\t游戏素材下载自免费游戏素材网站：https://kenney.nl/\n\t游戏关卡来自：http://sokoban.cn/ 中的经典关卡，去重后共237关。\n\t关卡和其他的内容将逐步更新。您如果有发现bug或者其他建议，欢迎将建议发送至我的邮箱，aya234@163.com\n\t一个人独立游戏制作不容易，如果您有心，可以捐赠支持一下。",
		"about.back": "返 回",
		"lang.button": "English",
	},
	"en": {
		"title.new": "New Game",
		"title.select": "Select Level",
		"title.about": "About",
		"title.exit": "Quit",
		"menu.prev": "Prev Level",
		"menu.next": "Next Level",
		"menu.reset": "Restart",
		"menu.back": "Main Menu",
		"menu.current": "Level: %s",
		"win.msg": "Level complete! Continue to the next one?",
		"win.quit": "Main Menu",
		"win.next": "Next Level",
		"win.last": "This is the last level!",
		"about.text": "About:\n\tUse the arrow keys or WASD to move the character.\n\tPush the boxes onto the target spots. After clearing a level you can go to the next one or return to the main menu; you can also switch levels with the Prev/Next buttons in game.\n\tArt assets from the free game-asset website: https://kenney.nl/\n\tClassic levels from http://sokoban.cn/, 237 levels after deduplication.\n\tMore levels and content coming soon. Found a bug or have a suggestion? Email me at aya234@163.com\n\tMaking a game all by yourself is not easy - donations are appreciated if you would like to support.",
		"about.back": "Back",
		"lang.button": "中文",
	},
}

func _ready():
	# autoload 早于一切场景 _ready，先恢复语言设置
	var cfg = ConfigFile.new()
	if cfg.load(LANG_CFG_PATH) == OK:
		lang = cfg.get_value("ui", "lang", "zh")
		if not TEXTS.has(lang):
			lang = "zh"
	# 恢复关卡解锁进度（首次运行为默认值）
	var progress = ConfigFile.new()
	if progress.load(PROGRESS_CFG_PATH) == OK:
		unlocked_count = max(DEFAULT_UNLOCKED, int(progress.get_value("progress", "unlocked", DEFAULT_UNLOCKED)))

func is_level_unlocked(index: int) -> bool:
	return index < unlocked_count

# 通关第 index 关（0 基）后调用：解锁下一关并持久化
func unlock_up_to(index: int) -> void:
	if index + 1 > unlocked_count:
		unlocked_count = index + 1
		var cfg = ConfigFile.new()
		cfg.set_value("progress", "unlocked", unlocked_count)
		cfg.save(PROGRESS_CFG_PATH)

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
		get_tree().change_scene(LEVEL_SCENE)

func get_level_display_name(path: String) -> String:
	return path.get_file().get_basename()

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
