extends Area3D

class_name Planet

# Properties
@export_range (0, 3) var spawn_buffer:float = 0
@export var use_spawn:bool = false
@export var props:PlanetProperties
@export var orbiting:bool = false

# Nodes
@onready var vox_gen:VoxGen = $VoxGen
@onready var pivot:PlayerPivot
@onready var collider:CollisionShape3D = get_node("%CollisionShape3D")
@onready var spawn_cast:RayCast3D = $SpawnCast

# Xforms
func xformed(spatial:Node3D): return spatial.global_position * global_transform
var player_pos = Vector3()

# Signals
signal player_entered
signal player_exited
signal props_changed
var exiting = false


### Triggers

func _on_Planet_child_entered_tree(node):
	if node is VoxGen:
		node.props = props

func _init():
	init_neighbors()

func _ready():
	props.init()
	props.changed.connect(_on_Props_changed)
	collider.shape.extents = props.world_dims * props.voxel_size

var last_player_pos:Vector3
func _physics_process(_delta):
	if pivot and orbiting:
		player_pos = xformed(pivot) #xformed(pivot.player)
		if last_player_pos != player_pos:
			prioritize()
			last_player_pos = player_pos
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

func _on_Props_changed():
	emit_signal("props_changed")

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
		last_chunk_pos = chunk_pos
		for neighbor in neighbors:
			var cur = chunk_pos + neighbor
			var greater = Vectors.any_lesser(cur, Vector3.ZERO)
			var lesser = Vectors.any_greater(cur, props.last_chunk)
			if not greater and not lesser:
				vox_gen.enqueue_pos(cur)


### Player Spawn
func spawn_player():
	# Properties
	#var _player = pivot.player
	var spawn_axis = vox_gen.spawn_axis
	var spawn_dir = vox_gen.spawn_dir
	var dim:float = props.chunk_dims[spawn_axis]
	var top:float = props.chunk_counts[spawn_axis] * dim
	# Setup ray cast
	var cast_vector = Vector3(0,0,0)
	cast_vector[spawn_axis] = top * spawn_dir
	spawn_cast.position = cast_vector
	spawn_cast.target_position = -cast_vector
	# User ray cast
	spawn_cast.enabled = true
	spawn_cast.force_raycast_update()
	if spawn_cast.is_colliding():
		# Place player where the ray cast landed
		if pivot:
			pivot.global_position = spawn_cast.get_collision_point()
			pivot.global_position[spawn_axis] += (spawn_buffer * spawn_dir)
	spawn_cast.enabled = false
	
	reorient_player()


### Player Orientation

# Get the gravity based checked the player's location; reorient the player if needed.
var cur_gravity = Vector3()
func reorient_player():
	var _gravity = props.type().gravity_dir(player_pos).normalized()
	if pivot:
		pivot.reorient_player(_gravity)

# Orient the Player based on a given gravity vector
func orient_player(_gravity, last_gravity):
	var angle:float = -_gravity.angle_to(last_gravity)
	var axis:Vector3 = _gravity.cross(last_gravity).normalized()
	if axis!=Vector3() and axis.is_normalized(): # Vector3 and bool
		if angle != 0 and angle != -0:
			# Roll the basis
			if pivot:
				var _basis = pivot.target.basis.rotated(axis, angle)
				pivot.target.basis = _basis.orthonormalized()
	else:
		prints("Axis not normalized...", axis, "[%.2f]" % angle)
