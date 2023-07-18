extends Node2D

var game_finish = false

# warning-ignore:unused_argument
func _process(delta):
	if !game_finish:
		var destinations = get_tree().get_nodes_in_group("dest")
		game_finish = GlobalVar.check_finish(destinations)
	else:
		get_tree().paused = true
		$MainScene/successpane.visible = true
#		print("game finish!")
