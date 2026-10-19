extends Node2D

# 游戏介绍文字直接维护在 about.tscn 的 RichTextLabel 节点中，
# 此脚本只负责返回主菜单。
func _on_Button_pressed():
	get_tree().change_scene("res://scene/MainTitle.tscn")
