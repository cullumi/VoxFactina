extends Spatial

# Properties
export (float, 0, 3) var spawn_buffer:float = 0

# Nodes
onready var vox_gen:VoxGen = get_node("%VoxGen")
onready var player:Player = get_node("%Player")
onready var pivot:Spatial = get_node("%PlayerPivot")
onready var spawn_cast:RayCast = get_node("%SpawnCast")


### Signal Targets

func _ready():
	if vox_gen:
		vox_gen.start()

func _physics_process(_delta):
	reorient_player()

func _on_VoxGen_initialized():
	spawn_player()


### Player Spawn
func spawn_player():
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


### Player Orientation

# Get the gravity based on the player's location; reorient the player if needed.
var last_gravity = null
func reorient_player():
	var player_pos = player.global_translation
	var gravity = vox_gen.gravity_dir(player_pos).normalized()
	if gravity != last_gravity:
		last_gravity = gravity
		orient_player(gravity)

# Orient the Player based on a given gravity vector
var bases:Dictionary = {
	Vector3(0,1,0):{"x":Vector3(1,0,0),"y":Vector3(0,1,0),"z":Vector3(0,0,1)},
	Vector3(1,0,0):{"x":Vector3(0,0,1),"y":Vector3(1,0,0),"z":Vector3(0,1,0)},
	Vector3(0,0,1):{"x":Vector3(1,0,0),"y":Vector3(0,0,1),"z":Vector3(0,1,0)},
}
func orient_player(gravity):
	# Save the player's global position
	var player_pos = player.global_translation

	# Get the appropriate basis vectors
	var vecs:Dictionary = bases[gravity.abs()]
	vecs.y *= -gravity.sign()
	var basis = Basis(vecs.x, vecs.y, vecs.z)
	bdebug(basis, vecs, gravity) # Debugging
	
	var rotquat = basis.orthonormalized().get_rotation_quat()
	pivot.transform.basis = Basis(rotquat)
	var sig = -gravity.sign() # Makes sure the y direction has the right sign.
	pivot.transform.basis.y = pivot.transform.basis.y.abs() * sig

	# Keep the player in their original global position.
	player.global_translation = player_pos
	cross_debug() # Debugging


### Basis Debugging

# Used to see if the player has the same global "up" as it's pivot point.
var last_cross = null
func cross_debug():
	var new_cross = player.global_transform.basis.y.cross(pivot.transform.basis.y)
	if new_cross != last_cross:
		last_cross = new_cross
		prints("Y Cross:", last_cross)

# Prints out the whole basis matrix.
func bprint(basis:Basis):
	prints("\tbasis:\t| %2.f, %2.f, %2.f |" % [basis.x.x, basis.y.x, basis.z.x])
	prints("\t      \t| %2.f, %2.f, %2.f |" % [basis.x.y, basis.y.y, basis.z.y])
	prints("\t      \t| %2.f, %2.f, %2.f |" % [basis.x.z, basis.y.z, basis.z.z])

# Prints out the components for gravity-based orientation.
func bdebug(basis:Basis, vecs:Dictionary, gravity:Vector3):
	prints("\tgrav:", gravity)
	prints("\tx:", vecs.x)
	prints("\ty:", vecs.y)
	prints("\tz:", vecs.z)
	prints("\tx:", basis.x, "y:", basis.y, "z:", basis.z)
	bprint(basis)
