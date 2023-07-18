extends KinematicBody2D

onready var ray = $RayCast2D

func move(dir):
	var pos = GlobalVar.directions[dir] * GlobalVar.DISTANCE
	ray.cast_to = pos
	ray.force_raycast_update()
	
	if ray.is_colliding():
		return false
	else:
		self.position += pos
		return true
