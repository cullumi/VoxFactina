extends RigidBody3D

# Settings
@export var _model: Node3D# = $MeshInstance3D
@export var _camera: Node3D
@export var move_speed: float
@export var air_speed: float
@export var rotation_speed: float
@export var jump_initial_impulse: float

var local_gravity: Vector3 = Vector3()

var _should_reset := false
var _move_direction: Vector3 = Vector3()
var _last_strong_direction: Vector3 = Vector3()

@onready var _start_position := global_transform.origin


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _integrate_forces(state:PhysicsDirectBodyState3D) -> void:
	# handles if a player falls off a planet, reseting
	# their position if they hit the safety net.
	if _should_reset:
		state.transform.origin = _start_position
		_should_reset = false
	
	local_gravity = state.total_gravity.normalized()
	
	# To not orient quickly to the last input, we save a last strong direction,
	# this also ensures a good normalized value for the rotation basis.
	if _move_direction.length() > 0.2:
		_last_strong_direction = _move_direction.normalized()
	
	_move_direction = _get_model_oriented_input()
	_orient_character_to_direction(_last_strong_direction, state.step)
	
	if is_jumping(state):
		#_model.jump()
		apply_central_impulse(-local_gravity * jump_initial_impulse)
	if is_on_floor(state):# and not _model.is_falling():
		apply_central_force(_move_direction * move_speed)
	else:
		apply_central_force(_move_direction * air_speed)
	#_model.velocity = state.linear_velocity

func _get_model_oriented_input() -> Vector3: 
	var input_left_right := (
		Input.get_action_strength("left_0")
		- Input.get_action_strength("right_0")
	)
	var input_forward := (
		Input.get_action_strength("forward_0")
		- Input.get_action_strength("backward_0")
	)
	
	var raw_input = Vector2(input_left_right, input_forward)
	
	var input := Vector3.ZERO
	# This ensures correct analogue input strength in any direction with a joypad stick
	input.x = raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)
	
	#var camera_offset = _camera.global_position - _model.global_position
	#var direction = _model.transform.basis * camera_offset.normalized()
	#input = direction * input
	input = _model.transform.basis * input
	return input

func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := -local_gravity.cross(direction)
	if (direction != Vector3.ZERO and left_axis != Vector3.ZERO):
		var rotation_basis := Basis(left_axis, -local_gravity, direction).orthonormalized()
		print(rotation_basis)
		_model.transform.basis = _model.transform.basis.orthonormalized().slerp( #basis.get_rotation_quaternion
			rotation_basis, delta * rotation_speed
		)

func is_jumping(state: PhysicsDirectBodyState3D) -> bool:
	return !is_on_floor(state) && Input.get_action_strength("jump_0") > 0

func reset_position() -> void:
	pass

func is_on_floor(state: PhysicsDirectBodyState3D) -> bool:
	# Contacts_reported needs to be high enough to count all surfaces on body
	for contact in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(contact)
		# If the contact is below us we are on the floor
		if contact_normal.dot(-local_gravity) > 0.5:
			return true
	return false
