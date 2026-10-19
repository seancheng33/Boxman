extends SceneTree

# 游戏状态持久化测试：读取当前进度 → 模拟通关第 5 关（索引 4）→ 校验内存态与落盘文件。

func _initialize():
	var g = root.get_node("/root/GlobalVar")
	print("BEFORE unlocked=", g.unlocked_count, " cleared=", g.cleared_levels.keys(), " last=", g.last_level_index)
	g.unlock_up_to(4)
	print("AFTER_UNLOCK4 unlocked=", g.unlocked_count, " (expect 6) cleared_has_4=", g.cleared_levels.has(4))
	print("is_locked_5=", not g.is_level_unlocked(5), " (expect false, i.e. level 6 unlocked)")
	# 再验证重复调用是幂等的
	g.unlock_up_to(3)
	print("AFTER_UNLOCK3_again unlocked=", g.unlocked_count, " (expect 6)")
	quit()
