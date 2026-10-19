extends Node2D


func _ready():
	refresh_texts()

func refresh_texts():
	$new.text = GlobalVar.t("title.new")
	$change.text = GlobalVar.t("title.select")
	$about.text = GlobalVar.t("title.about")
	$exit.text = GlobalVar.t("title.exit")
	$lang.text = GlobalVar.t("lang.button")

func _on_new_pressed():
	GlobalVar.goto_level(0)

func _on_change_pressed():
	get_tree().change_scene("res://scene/choice.tscn")

func _on_about_pressed():
	get_tree().change_scene("res://scene/about.tscn")

func _on_exit_pressed():
	get_tree().quit()

func _on_lang_pressed():
	GlobalVar.toggle_lang()
	refresh_texts()
