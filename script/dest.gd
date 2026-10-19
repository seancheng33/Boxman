extends Area2D

var is_active = false

func _on_dest_body_entered(body):
	if body.is_in_group("box"):
		is_active = true

func _on_dest_body_exited(body):
	if body.is_in_group("box"):
		is_active = false
