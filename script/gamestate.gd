# GameState.gd
class_name GameState

var player_position: Vector2
var boxes_positions: PoolVector2Array

func new(player_pos, boxes_pos):
	player_position = player_pos
	boxes_positions = boxes_pos.duplicate()
