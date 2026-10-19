extends Node2D

func _ready():
	$Panel/previous.text = GlobalVar.t("menu.prev")
	$Panel/next.text = GlobalVar.t("menu.next")
	$Panel/reset.text = GlobalVar.t("menu.reset")
	$Panel/back.text = GlobalVar.t("menu.back")
	# 关卡名延迟到帧末再取：Godot _ready 先子后父，level_builder（根节点）
	# 应用 BOXMAN_LEVEL 覆盖晚于本节点，立即取值会拿到旧索引
	call_deferred("_refresh_level_label")

func _refresh_level_label():
	var scene_index = GlobalVar.get_current_level_index()
	var level_count = GlobalVar.get_level_list().size()
	$Panel/previous.disabled = scene_index <= 0
	# 下一关除边界外还要校验解锁状态，防止翻到未解锁的关卡
	$Panel/next.disabled = scene_index >= level_count - 1 or not GlobalVar.is_level_unlocked(scene_index + 1)
	var level_path: String = GlobalVar.get_level_list()[scene_index]
	$Panel/Label2.text = GlobalVar.t("menu.current") % GlobalVar.get_level_display_number(level_path)

func _on_back_pressed():
	get_tree().change_scene("res://scene/MainTitle.tscn")

func _on_reset_pressed():
	get_tree().reload_current_scene()

func _on_previous_pressed():
	GlobalVar.goto_level(GlobalVar.get_current_level_index() - 1)

func _on_next_pressed():
	GlobalVar.goto_level(GlobalVar.get_current_level_index() + 1)
