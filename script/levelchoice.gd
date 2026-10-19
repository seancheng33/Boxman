extends Panel

func _ready():
	for item in $Control.get_children():
		item.connect("pressed",self,"bt_press",[item.name])
	

func bt_press(level_name):
	# 按钮名形如 "Level101"，转 0 基索引后走统一导航（模板场景从 levels_txt/ 生成）
	if not level_name.begins_with("Level") or level_name.length() <= 5:
		return
	var index := int(level_name.substr(5)) - 1
	if index >= 0:
		GlobalVar.goto_level(index)
