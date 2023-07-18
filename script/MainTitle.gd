extends Node2D
	
	
func _on_new_pressed():
	get_tree().change_scene("res://level/Level01.tscn")

func _on_change_pressed():
	get_tree().change_scene("res://scene/choice.tscn")

func _on_about_pressed():
	get_tree().change_scene("res://scene/about.tscn")

func _on_exit_pressed():
	get_tree().quit()




