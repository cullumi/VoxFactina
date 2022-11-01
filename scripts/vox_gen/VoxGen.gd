extends Spatial

class_name VoxGen

# Properties
export (Resource) var props

# Spawn Orientation
enum AXES {X, Y, Z}
export (AXES) var spawn_axis = AXES.Y
export (int, -1, 1, 2) var spawn_dir = 1

# Dimensions
enum {X, Y, Z}

# Spawn Math
func vector_spawn():
	var vector = Vector3()
	vector[spawn_axis] = spawn_dir
	return vector
onready var spawn_vector = vector_spawn()
onready var spawn_height:float = (props.chunk_counts[spawn_axis]/2 * props.surface_level) * spawn_dir
func calc_spawn_offset():
	var off = props.center_pos[spawn_axis] + spawn_height
	off = floor(off) if spawn_height < 0 else ceil(off)
	return clamp(off, 0, props.chunk_counts[spawn_axis]-1)
onready var spawn_offset:float = calc_spawn_offset()
func calc_spawn_chunk():
	var pos = props.center_pos
	pos[spawn_axis] = spawn_offset
	return pos
onready var spawn_chunk:Vector3 = calc_spawn_chunk()


signal initialized()
var chunks:Dictionary = {}
var render_queue:RenderQueue = RenderQueue.new()


### Initialization

func _ready():
	randomize()
	VoxelFactory.VoxelSize = props.voxel_size
	VoxelFactory.update_vertices()
	VoxelFactory.DefaultMaterial = props.voxel_material

func start():
	initialize_chunks()
	render()

func initialize_chunks():
	# Add all chunks to Dictionary
	var vectors = Vectors.all(props.last_chunk, Vector3(), [Y,Z,X])
	var temp = null
	for pos in vectors:
		var off = props.offset(pos)
		var orig = props.unoffset(off)
		if temp != off:
			temp = off
			prints(pos, "->", off, "->", orig)
		chunks[pos] = Chunk.new(pos, props.offset(pos))
	render_queue.flood(chunks.values())
	
	# First Chunk (Where the Player Spawns)
	var _chunk = force_render(spawn_chunk)
	var under = spawn_chunk-spawn_vector
	while under.x >= 0 and under.y >= 0 and under.z >= 0:
		_chunk = force_render(under)
		under = under-spawn_vector
	var vector = Vector3()
	vector[spawn_axis] = spawn_dir
	
	emit_signal("initialized")

### Rendering

func enqueue_pos(pos:Vector3):
	var chunk = chunks[pos]
	chunk.priority = 1
	chunk.render_collision = true
	render_queue.enqueue(chunk)

func render():
	while true:
		while not render_queue.empty():
			var chunk:Chunk = render_queue.dequeue()
			if chunk and not chunk.in_render:
				chunk.in_render = true
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

func force_render(pos:Vector3) -> Chunk:
	render_queue.erase(chunks[pos])
	return finish_render(render_chunk(chunks[pos]))

func finish_render(chunk:Chunk) -> Chunk:  
	if chunk.instance != chunk.new_instance:
		if chunk.instance != null: 
			chunk.instance.queue_free()
		chunk.instance = chunk.new_instance
		if chunk.instance != null:
			assert(chunk.instance.mesh != null)
#			assert(chunk.instance.mesh.get_surface_count())
			add_child(chunk.instance) 
	chunk.in_render = false
	return chunk

func render_chunk(chunk:Chunk) -> Chunk:
	var voxels:Dictionary = {}
	add_voxels(chunk, props.from, props.to, voxels)
	if not voxels.empty():
		var s_tool:SurfaceTool = SurfaceTool.new()
		chunk.new_instance = MeshInstance.new()
		chunk.new_instance.translation = chunk.offset
		chunk.new_instance.use_in_baked_light = true
		chunk.new_instance.generate_lightmap = true
		chunk.new_instance.cast_shadow =GeometryInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		chunk.new_instance.mesh = MarchingCubes.create_mesh(voxels, props, s_tool)
#		chunk.new_instance.mesh = VoxelFactory.create_mesh(voxels, s_tool)
		chunk.render_collision = true
		if chunk.render_collision and chunk.new_instance.mesh.get_surface_count():
			chunk.new_instance.create_trimesh_collision()
		chunk.all_air = false
		chunk.has_air = voxels.size() < props.vox_count
	else:
		chunk.new_instance = null
		chunk.all_air = true
		chunk.has_air = true
	return chunk


### Voxel Generation

func add_voxels(chunk:Chunk, start:Vector3, end:Vector3, voxels=null):
	var count = 0
	var pos = start
	while pos != end:
		count += 1
		add_voxel(chunk, pos, voxels)
		pos = Vectors.count_to(pos, end, props.from)
		if count % props.voxel_rate == 0:
			yield(get_tree(), "idle_frame")
	add_voxel(chunk, pos, voxels)

func add_voxel(chunk:Chunk, base_pos:Vector3, voxels=null):
	var pos = props.voxoff(chunk.pos, base_pos)
	var color = props.type().get_voxel_color(pos)
	if color.a != 0:
		voxels[pos] = Voxel.new(base_pos, pos, color)#color
#	VoxelFactory.add_voxel(base_pos, color, voxels)
