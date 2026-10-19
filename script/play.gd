extends KinematicBody2D

onready var ray = $RayCast2D

var history: Array = []
const MAX_HISTORY_SIZE = 1000

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
	# 注意：get_nodes_in_group 是 SceneTree 的方法；get_tree().root 是 Viewport，没有它
	var boxes = get_tree().get_nodes_in_group("box")
	var positions = PoolVector2Array()
	for box in boxes:
		positions.append(box.global_position)
	return positions

func _input(event):
	if event.is_action_pressed("undo"):
		undo()
		return
	for dir in GlobalVar.directions:
		if event.is_action_pressed(dir):
			move(dir)

# 悔棋：回退到上一步状态（每一步成功移动后都会存档，初始状态常驻栈底）
func undo():
	if history.size() <= 1:
		return
	history.pop_back()
	var state: GameState = history.back()
	$AnimationPlayer.stop()
	global_position = state.player_position
	var boxes = get_tree().get_nodes_in_group("box")
	for i in boxes.size():
		boxes[i].global_position = state.boxes_positions[i]

func move(dir):
	$AnimationPlayer.play(dir)
	var pos = GlobalVar.directions[dir] * GlobalVar.DISTANCE
	ray.cast_to = pos
	ray.force_raycast_update()

	var moved := false
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("box") and collider.move(dir):
			self.position += pos
			moved = true
	else:
		self.position += pos
		moved = true

	if moved:
		_save_state()
