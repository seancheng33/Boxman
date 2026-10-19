extends Area2D

var is_active = false

func apply_theme(dest_rect: Rect2) -> void:
	$Tilesheet.region_rect = dest_rect

func _on_dest_body_entered(body):
	if body.is_in_group("box"):
		is_active = true
		# 不直接改箱子外观：同一物理帧内可能先 entered(B) 后 exited(A)，
		# 顺序不保证。延后一帧让箱子按自身位置统一重算，两种顺序结果一致。
		if body.has_method("notify_dest_changed"):
			body.notify_dest_changed()

func _on_dest_body_exited(body):
	if body.is_in_group("box"):
		is_active = false
		if body.has_method("notify_dest_changed"):
			body.notify_dest_changed()
