extends KinematicBody2D

onready var ray = $RayCast2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
