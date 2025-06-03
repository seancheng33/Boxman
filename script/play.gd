extends KinematicBody2D

onready var ray = $RayCast2D

var history:Array = []
const MAX_HISTORY_SIZE = 10 

var current_state: GameState = null

# Called when the node enters the scene tree for the first time.
func _ready():
	history.clear()
	
	_save_state()

func _save_state():
	var state = GameState.new(global_position, _get_boxes_positions())
	history.append(state)
	
	if history.size() > MAX_HISTORY_SIZE:
		history.pop_front()

func _get_boxes_positions() -> PoolVector2Array:
	var boxes = get_tree().root.get_nodes_in_group("boxes")
	var positions = PoolVector2Array()
	for box in boxes:
		positions.append(box.global_position)
	return positions

func _input(event):
	for dir in GlobalVar.directions:
		if event.is_action_pressed(dir):
			move(dir)
			
func move(dir):
	$AnimationPlayer.play(dir)
	var pos = GlobalVar.directions[dir] * GlobalVar.DISTANCE
	ray.cast_to = pos
	ray.force_raycast_update()

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("box") and collider.move(dir):
			self.position += pos
			
	else:
		self.position += pos
