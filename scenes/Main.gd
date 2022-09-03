extends Spatial

export (float, 0, 3) var spawn_buffer:float = 0

onready var vox_gen:VoxGen = get_node("%VoxGen")
onready var player:Player = get_node("%Player")
onready var spawn_cast:RayCast = get_node("%SpawnCast")

func _ready():
	if vox_gen:
		vox_gen.start()

func orient_player():
	pass
#	var grav_dir = vox_gen.gravity_dir(player.translation)
#	player.up_vector = -grav_dir
#	var forward = player.

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
		player.translation = spawn_cast.get_collision_point()
		player.translation[spawn_axis] += (spawn_buffer * -spawn_dir)
	spawn_cast.enabled = false
