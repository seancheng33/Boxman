extends SceneTree

# 只读校验：全新安装（user://progress.cfg 不存在）时的默认解锁状态。
# 用法: godot --no-window --path . -s tools/test_default_unlock.gd
# 期望: 默认解锁前 5 关（第 1~5 关可选，第 6 关锁定），且不产生任何存档写入。

func _initialize():
	var g = root.get_node("/root/GlobalVar")
	var f = File.new()
	var has_save: bool = f.file_exists(g._progress_cfg_path)
	print("SAVE_EXISTS=", has_save, " (expect false for fresh install)")
	print("PROGRESS_PATH=", g._progress_cfg_path)
	print("DEFAULT unlocked_count=", g.unlocked_count, " (expect 5)")
	var ok: bool = not has_save and g.unlocked_count == g.DEFAULT_UNLOCKED
	for i in range(6):
		var unlocked: bool = g.is_level_unlocked(i)
		var expect := i < 5
		print("level %d unlocked=%s (expect %s)" % [i + 1, unlocked, expect])
		if unlocked != expect:
			ok = false
	print("TEST_DONE ok=", ok)
	quit()
