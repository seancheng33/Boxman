extends Area2D

var is_active = false

func apply_theme(dest_rect: Rect2) -> void:
	$Tilesheet.region_rect = dest_rect

func _on_dest_body_entered(body):
	if body.is_in_group("box"):
		is_active = true
		if body.has_method("set_on_dest"):
			body.set_on_dest(true)

func _on_dest_body_exited(body):
	if body.is_in_group("box"):
		is_active = false
		if body.has_method("set_on_dest"):
			body.set_on_dest(false)
