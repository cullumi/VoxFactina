extends Spatial

# Properties
export (float, 0, 3) var spawn_buffer:float = 0

# Nodes
onready var vox_gen:VoxGen = get_node("%VoxGen")
onready var player:Player = get_node("%Player")
onready var pivot:Spatial = get_node("%PlayerPivot")
onready var spawn_cast:RayCast = get_node("%SpawnCast")

# Xforms
func player_xform(): return global_transform.xform_inv(player.global_translation)
var player_pos = Vector3()

### Triggers

func _ready():
	if vox_gen:
		vox_gen.start()

func _physics_process(_delta):
	if player:
		player_pos = player_xform()
		prioritize()
		if pivot:
			reorient_player()

func _on_VoxGen_initialized():
	if player and pivot:
		spawn_player()


### Render Queue
var last_chunk_pos = null
func prioritize():
	var chunk_pos = vox_gen.unoffset(player_pos).round()
	if chunk_pos != last_chunk_pos:
#		prints("Entered Chunk:", chunk_pos)
		last_chunk_pos = chunk_pos
		var start = chunk_pos-Vector3.ONE
		var end = chunk_pos+Vector3.ONE
		start = Vectors.clamp_to(start, Vector3.ZERO, vox_gen.last_chunk)
		end = Vectors.clamp_to(end, Vector3.ZERO, vox_gen.last_chunk)
#		prints(start, "->", end)
		var cur = start
		vox_gen.enqueue_pos(cur)
		while cur != end:
			cur = Vectors.count_to(cur, end, start)
			vox_gen.enqueue_pos(cur)


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
var cur_gravity = Vector3()
func reorient_player():
	var gravity = vox_gen.gravity_dir(player_pos).normalized()
	if gravity != cur_gravity:
		orient_player(gravity, cur_gravity)
		cur_gravity = gravity

# Orient the Player based on a given gravity vector
func orient_player(gravity, last_gravity):
	var angle = 90 - (gravity.dot(last_gravity) * 90)
	var axis = gravity.cross(last_gravity).normalized()
	if axis:
		# Roll the basis
		var basis = pivot.target.basis.rotated(axis, -deg2rad(angle))
		pivot.target.basis = basis.orthonormalized()

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
