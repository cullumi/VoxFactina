extends Area

class_name Planet

# Properties
export (float, 0, 3) var spawn_buffer:float = 0
export (bool) var use_spawn = false
export (Resource) var props
export (bool) var orbiting = false

# Nodes
onready var vox_gen:VoxGen = $VoxGen
onready var pivot:PlayerPivot
onready var collider:CollisionShape = get_node("%CollisionShape")
onready var spawn_cast:RayCast = $SpawnCast

# Xforms
func xformed(spatial:Spatial): return global_transform.xform_inv(spatial.global_translation)
var player_pos = Vector3()

# Signals
signal player_entered
signal player_exited
var exiting = false


### Triggers

func _on_Planet_child_entered_tree(node):
	if node is VoxGen:
		node.props = props

func _init():
	init_neighbors()

func _ready():
	collider.shape.extents = props.world_dims * props.voxel_size

func _physics_process(_delta):
	if pivot and orbiting:
		player_pos = xformed(pivot) #xformed(pivot.player)
		prioritize()
		if pivot:
			reorient_player()

func generate():
	if vox_gen:
		vox_gen.start()

func _on_VoxGen_initialized():
	if pivot and use_spawn:
		spawn_player()

func _on_Planet_body_entered(body):
	if body is Player:
		emit_signal("player_entered", self)

func _on_Planet_body_exited(body):
	if body is Player:
		emit_signal("player_exited", self)


### Render Queue
var neighbors:Array = []
func init_neighbors():
	var start:Vector3 = -Vector3.ONE
	var end:Vector3 = Vector3.ONE
	var cur = start
	neighbors.append(cur)
	while cur != end:
		cur = Vectors.count_to(cur, end, start)
		neighbors.append(cur)

var last_chunk_pos = null
func prioritize():
	var chunk_pos = props.unoffset(player_pos).round()
	if chunk_pos != last_chunk_pos:
		if chunk_pos.x < 0 or chunk_pos.y < 0 or chunk_pos.z < 0:
			prints(player_pos, "->", chunk_pos)
		last_chunk_pos = chunk_pos
		for neighbor in neighbors:
			var cur = chunk_pos + neighbor
			var greater = Vectors.lesser(cur, Vector3.ZERO)
			var lesser = Vectors.greater(cur, props.last_chunk)
			if not greater and not lesser:
				print("Enqueued")
#			if cur >= Vector3.ZERO and cur <= props.last_chunk:
				vox_gen.enqueue_pos(cur)
				yield(get_tree(), "idle_frame")


### Player Spawn
func spawn_player():
	print("Spawn")
	var _player = pivot.player
	var spawn_axis = vox_gen.spawn_axis
	var spawn_dir = vox_gen.spawn_dir
	var dim:float = props.chunk_dims[spawn_axis]
	var top:float = props.chunk_counts[spawn_axis] * dim
	var cast_vector = Vector3(0,0,0)
	cast_vector[spawn_axis] = top * spawn_dir
	spawn_cast.translation = cast_vector
	spawn_cast.cast_to = -cast_vector
	spawn_cast.enabled = true
	spawn_cast.force_raycast_update()
	if spawn_cast.is_colliding():
		pivot.global_translation = spawn_cast.get_collision_point()
		pivot.global_translation[spawn_axis] += (spawn_buffer * spawn_dir)
	spawn_cast.enabled = false
	prints("Spawned at:", pivot.global_translation)
	reorient_player()


### Player Orientation

# Get the gravity based on the player's location; reorient the player if needed.
var cur_gravity = Vector3()
func reorient_player():
	var gravity = props.type().gravity_dir(player_pos).normalized()
	pivot.reorient_player(gravity)

# Orient the Player based on a given gravity vector
func orient_player(gravity, last_gravity):
	var angle:float = -gravity.angle_to(last_gravity)
	var axis:Vector3 = gravity.cross(last_gravity).normalized()
	if axis and axis.is_normalized():
		if angle != 0 and angle != -0:
			# Roll the basis
			var basis = pivot.target.basis.rotated(axis, angle)
			pivot.target.basis = basis.orthonormalized()
	else:
		prints("Axis not normalized...", axis, "[%.2f]" % angle)
