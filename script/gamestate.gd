# GameState.gd
class_name GameState

var player_position: Vector2
var boxes_positions: PoolVector2Array

func _init(player_pos: Vector2 = Vector2.ZERO, boxes_pos: PoolVector2Array = PoolVector2Array()):
	player_position = player_pos
	# 注意：Godot 3.x 的 Pool*Array 赋值即按值拷贝（COW），没有 duplicate() 方法
	boxes_positions = boxes_pos
