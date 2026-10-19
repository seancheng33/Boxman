# 无头数据校验脚本（-s 方式运行，无 autoload，手动实例化 global.gd）
# 用法: godot --no-window --path . -s tools/check_data.gd
extends SceneTree

func _init():
	var G = load("res://script/global.gd").new()
	var list = G.get_level_list()
	print("关卡文件数: ", list.size())
	var bad: Array = []
	var total_boxes := 0
	var total_walls := 0
	for i in list.size():
		var d: Dictionary = G.load_level_data(list[i])
		var ok: bool = not d.empty()
		if ok:
			ok = d.player.x > -9000
		if ok:
			ok = int(d.boxes.size()) >= int(d.dests.size()) and int(d.dests.size()) > 0
		if ok:
			# 墙里不应有箱子/目标/玩家重叠
			var wall_set := {}
			for w in d.walls:
				wall_set[w] = true
			for c in d.boxes:
				if wall_set.has(c):
					ok = false
			for c in d.dests:
				if wall_set.has(c):
					ok = false
			if wall_set.has(d.player):
				ok = false
		if not ok:
			bad.append(list[i])
		else:
			total_boxes += int(d.boxes.size())
			total_walls += int(d.walls.size())
	print("异常关卡数: ", bad.size(), " ", bad)
	print("总箱子数: ", total_boxes, "  总墙数: ", total_walls)
	print("RESULT: %s" % ("PASS" if (bad.size() == 0 and list.size() == 237) else "FAIL"))
	quit()
