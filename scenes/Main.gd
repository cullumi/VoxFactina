extends Spatial

export (float, 0, 3) var spawn_buffer:float = 0

onready var vox_gen:VoxGen = get_node("%VoxGen")
onready var player:Player = get_node("%Player")
onready var pivot:Spatial = get_node("%PlayerPivot")
onready var spawn_cast:RayCast = get_node("%SpawnCast")

func _ready():
	if vox_gen:
		vox_gen.start()

func _physics_process(_delta):
	reorient_player()

var last_gravity = null
func reorient_player():
	var player_pos = player.global_translation
	var gravity = vox_gen.gravity_dir(player_pos).normalized()
	if gravity != last_gravity:
		last_gravity = gravity
		orient_player(gravity)

var last_cross = null
func orient_player(gravity):
	var player_pos = player.global_translation

	var x = Vector3(1,0,0)
	var y = Vector3(0,1,0)
	var z = Vector3(0,0,1)
	match gravity:
		Vector3(0,1,0):
			x = Vector3(-1,0,0)
			y = Vector3(0,-1,0)
			z = Vector3(0,0,-1)
		Vector3(0,-1,0):
			x = Vector3(1,0,0)
			y = Vector3(0,1,0)
			z = Vector3(0,0,1)
		Vector3(1,0,0):
			x = Vector3(0,0,-1)
			y = Vector3(-1,0,0)
			z = Vector3(0,-1,0)
		Vector3(-1,0,0):
			x = Vector3(0,0,1)
			y = Vector3(1,0,0)
			z = Vector3(0,1,0)
		Vector3(0,0,1):
			x = Vector3(1,0,0)
			y = Vector3(0,0,1)
			z = Vector3(0,1,0)
		Vector3(0,0,-1):
			x = Vector3(1,0,0)
			y = Vector3(0,0,-1)
			z = Vector3(0,1,0)

#	var direction
#	var left
#	if gravity.x == 0:
#		direction = -Vector3(gravity.x, gravity.z, gravity.y)
#	else:
#		direction = -Vector3(gravity.y, gravity.x, gravity.z)
#	left = -gravity.cross(direction)
#	var basis = Basis(left, -gravity, direction)
	
	var basis = Basis(x, y, z)
	if gravity == Vector3(1,0,0) or gravity == Vector3(-1,0,0):
		print("\nX Axis")
	else:
		print("\nOther")
	prints("\tgrav:", gravity)
	prints("\tx:", x)
	prints("\ty:", y)
	prints("\tz:", z)
	prints("\tx:", basis.x, "y:", basis.y, "z:", basis.z)
	prints("\tbasis:", basis)
	prints("\tx:", basis.x, "y:", basis.y, "z:", basis.z)
	prints("\tbasis:", basis)
	
	var orthoed = basis.orthonormalized()
	var rotquat = orthoed.get_rotation_quat()
	if not rotquat.is_normalized():
		prints("Quat not normal:", rotquat)
	pivot.transform.basis = Basis(rotquat)
#	pivot.transform.basis = Basis(left, -gravity, direction).get_rotation_quat()

	player.global_translation = player_pos
	var new_cross = player.transform.basis.y.cross(pivot.transform.basis.y)
	if new_cross != last_cross:
		last_cross = new_cross
		prints("Y Cross:", last_cross)

func _on_VoxGen_initialized():
	print("Spawn")
	var spawn_axis = vox_gen.spawn_axis
	var spawn_dir = vox_gen.spawn_dir
	var dim:float = vox_gen.chunk_dims[spawn_axis]
	var top:float = vox_gen.chunk_counts[spawn_axis] * dim / 2
	var cast_vector = Vector3(0,0,0)
	cast_vector[spawn_axis] = top*2 * spawn_dir
	spawn_cast.translation = cast_vector
	spawn_cast.cast_to = -cast_vector
	spawn_cast.enabled = true
	spawn_cast.force_raycast_update()
	if spawn_cast.is_colliding():
		player.global_translation = spawn_cast.get_collision_point()
		player.global_translation[spawn_axis] += (spawn_buffer * spawn_dir)
	spawn_cast.enabled = false
	prints("Spawned at:", player.global_translation)
	reorient_player()
