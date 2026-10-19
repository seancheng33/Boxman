extends Node2D

# 运行时关卡构建器：从 levels_txt/ 的 ASCII 关卡文件生成墙 / 目标 / 箱子 / 玩家，
# 并承担原 LevelCheck.gd 的通关检测职责。
# 测试辅助：设置环境变量 BOXMAN_LEVEL=<索引>（0 基）可直接构建指定关卡。

const TILE := 64
const TILEMAP_SCENE := preload("res://scene/TileMap.tscn")
const BOX_SCENE := preload("res://scene/box.tscn")
const DEST_SCENE := preload("res://scene/dest.tscn")
const PLAY_SCENE := preload("res://scene/play.tscn")

var game_finish := false

func _ready():
	_apply_env_override()
	_build_level()

func _apply_env_override():
	var env_idx := OS.get_environment("BOXMAN_LEVEL")
	if env_idx != "" and env_idx.is_valid_integer():
		GlobalVar.current_level_index = int(env_idx)

func _build_level():
	var list = GlobalVar.get_level_list()
	var index: int = clamp(GlobalVar.current_level_index, 0, list.size() - 1)
	var data: Dictionary = GlobalVar.load_level_data(list[index])
	if data.empty():
		push_error("关卡数据为空: " + list[index])
		return

	# 墙：TileMap 放在原点，格子坐标即真实网格坐标，世界位置与旧版逐格一致
	var tilemap = TILEMAP_SCENE.instance()
	tilemap.position = Vector2.ZERO
	add_child(tilemap)
	for cell in data.walls:
		tilemap.set_cellv(cell, 0)

	# 目标 → 箱子 → 玩家（后添加的绘制在上层，与旧版层级一致）
	for cell in data.dests:
		var d = DEST_SCENE.instance()
		d.position = cell * TILE
		add_child(d)
	for cell in data.boxes:
		var b = BOX_SCENE.instance()
		b.position = cell * TILE
		add_child(b)
	var p = PLAY_SCENE.instance()
	p.position = data.player * TILE
	add_child(p)

# ---- 通关检测（原 LevelCheck.gd 逻辑）----

func _process(_delta):
	if game_finish:
		return
	var destinations = get_tree().get_nodes_in_group("dest")
	if GlobalVar.check_finish(destinations):
		game_finish = true
		get_tree().paused = true
		$MainScene/successpane.visible = true
