extends Panel

func _ready():
	for item in $Control.get_children():
		item.connect("pressed",self,"bt_press",[item.name])
		refresh_lock_state(item)

func refresh_lock_state(item: Node):
	# 按钮名形如 "Level101"，未解锁的关卡置灰并禁止点击
	# 注：Godot 3 默认主题不会压暗 disabled 按钮的 icon，需用 self_modulate 手动置灰
	if not item.name.begins_with("Level") or item.name.length() <= 5:
		return
	var index := int(item.name.substr(5)) - 1
	var unlocked: bool = GlobalVar.is_level_unlocked(index)
	item.disabled = not unlocked
	item.self_modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.35, 0.35, 0.85)

func bt_press(level_name):
	# 按钮名形如 "Level101"，转 0 基索引后走统一导航（模板场景从 levels_txt/ 生成）
	if not level_name.begins_with("Level") or level_name.length() <= 5:
		return
	var index := int(level_name.substr(5)) - 1
	if index >= 0 and GlobalVar.is_level_unlocked(index):
		GlobalVar.goto_level(index)
