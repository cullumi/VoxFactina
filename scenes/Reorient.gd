extends Spatial

func _physics_process(_delta):
	var direction := Vector3.DOWN
	var gravity := -global_translation
	var left := -gravity.cross(direction)
	var basis = Basis(left, -gravity, direction)
	var orthoed = basis.orthonormalized()
	var rotquat = orthoed.get_rotation_quat()
	transform.basis = Basis(rotquat)
#	transform.basis = Basis(left, -gravity, direction).get_rotation_quat()
