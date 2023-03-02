extends Node3D

func _physics_process(_delta):
	var direction := Vector3.DOWN
	var gravity := -global_position
	var left := -gravity.cross(direction)
	var _basis = Basis(left, -gravity, direction)
	var orthoed = _basis.orthonormalized()
	var rotquat = orthoed.get_rotation_quaternion()
	transform.basis = Basis(rotquat)
#	transform.basis = Basis(left, -gravity, direction).get_rotation_quaternion()
