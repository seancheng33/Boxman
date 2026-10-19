extends Node2D

# 介绍文字（中/英）维护在 global.gd 的 TEXTS 表中，此处按当前语言刷新。
func _ready():
	$RichTextLabel.text = GlobalVar.t("about.text")
	$Button.text = GlobalVar.t("about.back")

func _on_Button_pressed():
	get_tree().change_scene("res://scene/MainTitle.tscn")
