extends Spatial

class_name VoxGen

# Properties
export (Vector3) var from:Vector3 = Vector3(-10, -10, -10)
export (Vector3) var to:Vector3 = Vector3(10, 10, 10)
export (Vector3) var chunk_counts:Vector3 = Vector3(3, 3, 3)
export (float, 0, 1, 0.05) var surface_level:float = 0.75
export (float, 0.1, 1, 0.05) var voxel_size:float = 1
export (float, EXP, 1000, 1000000, 1000) var voxel_rate:int = 10000

# Spawn Orientation
enum AXES {X, Y, Z}
export (AXES) var spawn_axis = AXES.Y
export (int, -1, 1, 2) var spawn_dir = 1

# Dimensions
enum {X, Y, Z}
onready var chunk_dims:Vector3 = to - from
onready var world_dims:Vector3 = chunk_dims * chunk_counts
onready var world_radii:Vector3 = world_dims/2

# Locations
onready var last_chunk:Vector3 = chunk_counts-Vector3(1,1,1)
onready var center_chunk:Vector3 = last_chunk/2
onready var center_pos:Vector3 = center_chunk.floor()
onready var spawn_height:float = (chunk_counts[spawn_axis]/2 * surface_level) * spawn_dir
func calc_spawn_offset():
	var off = center_pos[spawn_axis] + spawn_height
	if spawn_height > 0: return ceil(off)
	else: return floor(off)
onready var spawn_offset:float = calc_spawn_offset()
func calc_spawn_chunk():
	var pos = center_pos
	pos[spawn_axis] = spawn_offset
	return pos
onready var spawn_chunk:Vector3 = calc_spawn_chunk()

# Offsets
onready var chunk_offset = (Vector3(chunk_dims.x, 0, chunk_dims.z)/2)
func offset(pos:Vector3):
	var pos_offset = pos - center_chunk
	return (chunk_dims * pos_offset) + chunk_offset

# Surface Level Rects
onready var front_radii = Vector2(world_radii.x, world_radii.y) * surface_level
onready var top_radii = Vector2(world_radii.x, world_radii.z) * surface_level
onready var front = Rect2(-front_radii, front_radii*2)
onready var top = Rect2(-top_radii, top_radii*2)

signal initialized()
var chunks:Dictionary = {}
var render_queue:RenderQueue = RenderQueue.new()


### Initialization

func _ready():
	randomize()
	VoxelFactory.VoxelSize = voxel_size
	VoxelFactory.update_vertices()

func start():
	initialize_chunks()
	render()

func initialize_chunks():
	# Add all chunks to Dictionary
	for pos in Vectors.all(last_chunk, Vector3(), [Y,Z,X]):
		chunks[pos] = Chunk.new(offset(pos))
	render_queue.flood(chunks.values())
	
	# First Chunk (Where the Player Spawns)
	force_render(spawn_chunk)
	
	emit_signal("initialized")


### Rendering

func render():
	while true:
		if not render_queue.empty():
			var chunk:Chunk = render_queue.dequeue()
			while true:
				var res = ThreadPool.start_job(
					self, "render_chunk", [chunk],
					self, "finish_render"
				)
				if res:
					break
				else:
					yield(ThreadPool, "idling")
		yield(get_tree(), "idle_frame")

func force_render(pos:Vector3):
	render_queue.erase(chunks[pos])
	finish_render(render_chunk(chunks[pos]))

func finish_render(chunk):
	if chunk.instance != null:
		chunk.instance.queue_free()
	chunk.instance = chunk.new_instance
	if chunk.instance != null:
		add_child(chunk.instance)

func render_chunk(chunk:Chunk):
	var voxels:Dictionary = {}
	add_voxels(chunk, from, to, voxels)
	if not voxels.empty():
		var s_tool:SurfaceTool = SurfaceTool.new()
		chunk.new_instance = MeshInstance.new()
		chunk.new_instance.use_in_baked_light = true
		chunk.new_instance.generate_lightmap = true
		chunk.new_instance.cast_shadow =GeometryInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		chunk.new_instance.mesh = VoxelFactory.create_mesh(voxels, s_tool)
		assert(chunk.new_instance.mesh != null)
		chunk.new_instance.create_trimesh_collision()
	else:
		chunk.new_instance = null
	return chunk


### Voxel Generation

func add_voxels(chunk:Chunk, start:Vector3, end:Vector3, voxels=null):
	var count = 0
	var pos = start
	while pos != end:
		count += 1
		add_voxel(chunk, pos, voxels)
		pos = Vectors.count_to(pos, end, from)
		if count % voxel_rate == 0:
			yield(get_tree(), "idle_frame")
	add_voxel(chunk, pos, voxels)

func add_voxel(chunk:Chunk, base_pos:Vector3, voxels=null):
	var pos = base_pos + chunk.offset
	var color = get_voxel_color(pos)
	VoxelFactory.add_voxel(pos, color, voxels)

## Content Queries

func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = randi()
		return Color.forestgreen if rand % 2 else Color.darkolivegreen

func voxel_is_air(pos:Vector3) -> bool:
	var in_front = front.has_point(Vector2(pos.x, pos.y))
	var in_top = top.has_point(Vector2(pos.x, pos.z))
	return not in_front or not in_top


### Calculations

## Gravity Direction
func gravity_dir(pos:Vector3) -> Vector3:
	var norm = pos.normalized().abs()
	var axis = X if norm.x > norm.y else Y
	axis = axis if norm[axis] > norm.z else Z
	var final = Vector3()
	final[axis] = -sign(pos[axis])
	return final

## Conversions
func pos_to_chunk(pos:Vector3) -> Vector3:
	return Vector3()
