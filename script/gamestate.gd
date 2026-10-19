# GameState.gd
class_name GameState

var player_position: Vector2
var boxes_positions: PoolVector2Array

func _init(player_pos: Vector2 = Vector2.ZERO, boxes_pos: PoolVector2Array = PoolVector2Array()):
	player_position = player_pos
	boxes_positions = boxes_pos.duplicate()
