extends KinematicBody2D

onready var ray = $RayCast2D
onready var sprite = $Tilesheet

# 分关配色：普通/压点两种 region，由 level_builder 按主题注入
var _rect_normal: Rect2 = Rect2(256, 0, 64, 64)
var _rect_on_dest: Rect2 = Rect2(256, 64, 64, 64)
var on_dest := false

func apply_theme(box_rect: Rect2, box_on_dest_rect: Rect2) -> void:
	_rect_normal = box_rect
	_rect_on_dest = box_on_dest_rect
	sprite.region_rect = _rect_on_dest if on_dest else _rect_normal

# 由 dest.gd 在箱子进入/离开目标点时调用，切换同色暗版图形
func set_on_dest(value: bool) -> void:
	if on_dest == value:
		return
	on_dest = value
	sprite.region_rect = _rect_on_dest if on_dest else _rect_normal

func move(dir):
	var pos = GlobalVar.directions[dir] * GlobalVar.DISTANCE
	ray.cast_to = pos
	ray.force_raycast_update()

	if ray.is_colliding():
		return false
	else:
		self.position += pos
		return true
