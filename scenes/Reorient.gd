extends Spatial

func _physics_process(_delta):
	var direction := Vector3.DOWN
	var gravity := -global_translation
	var left := -gravity.cross(direction)
	transform.basis = Basis(left, -gravity, direction).get_rotation_quat()
