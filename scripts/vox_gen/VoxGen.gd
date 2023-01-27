extends Spatial

class_name VoxGen

### Properties

# Planet Properties
export (Resource) var props

# Spawn Orientation
enum AXES {X, Y, Z}
export (AXES) var spawn_axis = AXES.Y
export (int, -1, 1, 2) var spawn_dir = 1
export (int, 1, 4) var lod_number = 1

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

# Octree & Render Queue
signal initialized()
var chunks:Dictionary = {}
var render_queue:RenderQueue = RenderQueue.new()
var levels:int = 1
var lods:Array = []
var lod_nodes:Array = []
var trail_parent:Node


### Initialization

func _ready():
	randomize()
	VoxelFactory.VoxelSize = props.voxel_size
	VoxelFactory.update_vertices()
	VoxelFactory.DefaultMaterial = props.voxel_material

func start():
	initialize()
	render()

func initialize():
	# Initialize Chunk Octree
	lods = Octree.create(props)
	chunks = lods.back()
	add_lod_parents()
	Tests.np_chunks_check(chunks, props)
	var root:Chunk = lods.front()[Vector3()]
	
	# Render
	var to_render:Array = deform_lods(root)
	render_queue.flood(to_render)
	prints("Rendered:", Tests.render_check(root))
	initialize_spawn_chunks()
	
	emit_signal("initialized")

func add_lod_parents():
	trail_parent = Node.new()
	trail_parent.name = "Trail"
	add_child(trail_parent)
	for l in range(lods.size()):
		lod_nodes.append(Node.new())
		lod_nodes[l].name = "Lod " + String(l)
		add_child(lod_nodes[l])

func deform_lods(root:Chunk) -> Array:
	var chunk_depths:Dictionary = root.deform_at(spawn_chunk)
	var to_render:Array = []
	Tests.print_chunk_depths(chunk_depths)
	for depth in range(lods.size()):
		var chunks_at_depth:Array = chunk_depths.get(depth, [])
		to_render.append_array(chunks_at_depth)
	Tests.octree_count(to_render, lods, chunks)
	return to_render

var spawn_axes:Dictionary = {
	AXES.X:[Vector3(), Vector3.UP, Vector3.BACK, Vector3(0,1,1)],
	AXES.Y:[Vector3(), Vector3.RIGHT, Vector3.BACK, Vector3(1,0,1)],
	AXES.Z:[Vector3(), Vector3.RIGHT, Vector3.UP, Vector3(1,1,0)],
}
func initialize_spawn_chunks():
	for corner in spawn_axes[spawn_axis]:
		var spawn_pos = spawn_chunk + corner
		var _chunk = force_render(spawn_pos)
		var under = spawn_pos-spawn_vector
		while under.x >= 0 and under.y >= 0 and under.z >= 0:
			_chunk = force_render(under)
			under = under-spawn_vector

### Render Triggers

func force_render(pos:Vector3) -> Chunk:
	render_queue.erase(chunks[pos])
	return finish_render(render_chunk(chunks[pos]))

func enqueue_pos(pos:Vector3):
	var chunk:Chunk = chunks.get(pos)
	if chunk:
		if not chunk.is_rendered and not chunk.in_render:
			chunk.deform_on_finish = true
			chunk.priority = 1
			chunk.render_collision = true
			render_queue.enqueue(chunk)
	else:
		printerr("Chunk at " + String(pos) + " does not exist")


### Render Queue Managment

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

func finish_render(chunk:Chunk) -> Chunk:
	var deformed:Array = chunk.finish_render(lod_nodes[chunk.depth])
	if chunk.instance != null and chunk.instance.get_surface_material_count() > 0:
		Tests.leave_trail(trail_parent, chunk, props)
	if chunk.deform_on_finish:
		for child in deformed:
			render_queue.enqueue(child)
	return chunk


### Chunk Rendering

func render_chunk(chunk:Chunk) -> Chunk:
	var voxels:Dictionary = {}
	add_voxels(chunk, props.relative_voxel_positions, voxels)
	if not voxels.empty():
		var s_tool:SurfaceTool = SurfaceTool.new()
		chunk.new_instance = MeshInstance.new()
		chunk.new_instance.translation = chunk.offset
		chunk.new_instance.use_in_baked_light = true
		chunk.new_instance.generate_lightmap = true
		chunk.new_instance.cast_shadow =GeometryInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		chunk.new_instance.mesh = MarchingCubes.create_mesh(chunk.scale, voxels, props, s_tool)
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

func add_voxels(chunk:Chunk, vectors:Array=[], voxels=null):
	for vector in vectors:
		add_voxel(chunk, vector, voxels)

func add_voxel(chunk:Chunk, base_pos:Vector3, voxels=null):
	var scale_pos:Vector3 = base_pos * chunk.scale
	var vox_pos = props.voxlocal(chunk.pos, scale_pos, chunk.depth)
	var color = props.type().get_voxel_color(vox_pos)
	if color.a != 0:
		voxels[vox_pos] = Voxel.new(scale_pos, vox_pos, color)
