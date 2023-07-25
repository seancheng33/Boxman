extends Node2D


func _ready():
	var about_file = File.new()
	about_file.open("user://assets/about_data/about.txt",File.READ)
	print(about_file)
	about_file.close()

func _on_Button_pressed():
	get_tree().change_scene("res://scene/MainTitle.tscn") 
