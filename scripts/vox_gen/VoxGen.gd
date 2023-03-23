extends Node3D

class_name VoxGen

### Properties

# Planet Properties
@export var props:PlanetProperties

# Spawn Orientation
enum AXES {X, Y, Z}
@export var spawn_axis:AXES = AXES.Y
@export_range (-1, 1, 2) var spawn_dir:int = 1
@export_range (1, 4, 1) var lod_number = 1

# Dimensions
enum {X, Y, Z}

# Spawn Math
func vector_spawn():
	var vector = Vector3()
	vector[spawn_axis] = spawn_dir
	return vector
@onready var spawn_vector = vector_spawn()
@onready var spawn_height:float = (props.chunk_counts[spawn_axis]/2.0 * props.surface_level) * spawn_dir
func calc_spawn_offset():
	var unchecked = props.center_pos[spawn_axis] + spawn_height
	unchecked = floor(unchecked) if spawn_height < 0 else ceil(unchecked)
	return clamp(unchecked, 0, props.chunk_counts[spawn_axis]-1)
@onready var spawn_offset:float = calc_spawn_offset()
func calc_spawn_chunk():
	var pos = props.center_pos
	pos[spawn_axis] = spawn_offset
	return pos
@onready var spawn_chunk:Vector3 = calc_spawn_chunk()

# Octree & Render Queue
@export var debug:bool = true :
	set(val): debug=val; Tests.show_debug=val
signal initialized()
var chunks:Dictionary = {}
var render_queue:RenderQueue = RenderQueue.new()
var levels:int = 1
var octree:Octree = Octree.new()
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
	debug_print("\n\t\t\t\t\t\t\t\tINITIALIZE OCTREE\n")
	var spawn_pos = spawn_chunk
	var lods_to_render = octree.create(props, spawn_pos)
	chunks = octree.lods.back()
	print(octree.depth(props))
	add_lod_parents()
	Tests.np_chunks_check(chunks, props)
	
	# Render
	debug_print("\n\t\t\t\t\t\t\t\tRENDER LODS\n")
	render_lods(lods_to_render)
	debug_prints(["Rendered:", str(Tests.render_check(octree.root))])
	initialize_spawn_chunks()
	debug_print("\n\t\t\t\t\t\t\t\tINITIALIZED\n")
	emit_signal("initialized")

func add_lod_parents():
	debug_prints(["parents:", str(props.lod_count)])
	trail_parent = Node.new()
	trail_parent.name = "Trail"
	add_child(trail_parent)
	for l in range(props.lod_count):
		lod_nodes.append(Node.new())
		lod_nodes[l].name = "Lod " + str(l)
		add_child(lod_nodes[l])

func render_lods(lods_to_render=lods):
	var to_render:Array = []
	Tests.print_chunk_depths(lods_to_render)
	
	# Determine Depths
	var depths:Array
	if lods_to_render is Dictionary:
		depths = lods_to_render.keys().duplicate()
		depths.sort()
	else:
		depths = range(lods.size())
	
	# Compile Chunks
	for depth in depths:
		to_render.append_array(lods_to_render[depth])
	
	# Flood
	Tests.octree_count(to_render, octree.lods, chunks)
	render_queue.flood(to_render)

var spawn_axes:Dictionary = {
	AXES.X:[Vector3(), Vector3.UP, Vector3.BACK, Vector3(0,1,1)],
	AXES.Y:[Vector3(), Vector3.RIGHT, Vector3.BACK, Vector3(1,0,1)],
	AXES.Z:[Vector3(), Vector3.RIGHT, Vector3.UP, Vector3(1,1,0)],
}
func initialize_spawn_chunks():
	pass
#	var spawn_max = props.chunk_counts / 2
#	for corner in spawn_axes[spawn_axis]:
#		var spawn_pos = spawn_chunk + corner
#		var _chunk = force_render(spawn_pos)
#		var under = spawn_pos-spawn_vector
#		while under.x >= spawn_max.x and under.y >= spawn_max.y and under.z >= spawn_max.z:
#			_chunk = force_render(under)
#			under = under-spawn_vector


###
func debug_prints(items:Array):
	if not debug: return
	var final = ""
	for item in items:
		final += str(item) + " "
	final.strip_edges(false, true)
	print(final)

func debug_print(string:String):
	if debug: print(string)


### Render Triggers

func force_render(pos:Vector3) -> Chunk:
	assert(chunks.has(pos))
	render_queue.erase(chunks[pos])
	return finish_render(render_chunk(chunks[pos]))

func enqueue_pos(pos:Vector3):
	var chunk:Chunk = chunks.get(pos)
	if not chunk:
		var lods_to_render = octree.root.deform_at(pos)
		render_lods(lods_to_render)
	elif chunk:
		if not chunk.is_rendered and not chunk.in_render:
			chunk.deform_on_finish = true
			chunk.priority = 1
			chunk.render_collision = true
			render_queue.enqueue(chunk)
	else:
		printerr("Chunk at " + str(pos) + " does not exist")


### Render Queue Managment

func render():
	while true:
		while not render_queue.is_empty():
			var chunk:Chunk = render_queue.dequeue()
			if chunk and not chunk.in_render:
				chunk.in_render = true
				while true:
					var worker:Worker = ThreadPool.start_job(
						render_chunk, [chunk],
						finish_render
					)
					if worker:
						chunk.worker = worker
						break
					else:
						await ThreadPool.idling
		await get_tree().process_frame

func finish_render(chunk:Chunk) -> Chunk:
	assert(chunk)
	chunk.worker = null
	var deformed:Array = chunk.finish_render(lod_nodes[chunk.depth])
	if chunk.instance != null and chunk.instance.get_surface_override_material_count() > 0:
		Tests.leave_trail(trail_parent, chunk, props)
	if chunk.deform_on_finish:
		for child in deformed:
			render_queue.enqueue(child)
	return chunk


### Chunk Rendering

var rendered_chunks:Dictionary = {}
func render_chunk(chunk:Chunk) -> Chunk:
	var voxels:Dictionary = {}
	add_voxels(chunk, props.relative_voxel_positions, voxels)
	if not voxels.is_empty():
		construct_instance(chunk, voxels)
	else:
		chunk.new_instance = null
		chunk.all_air = true
		chunk.has_air = true
	return chunk

func construct_instance(chunk, voxels):
	var s_tool:SurfaceTool = SurfaceTool.new()
	var mesh = MarchingCubes.create_mesh(chunk.scale, voxels, props, chunk.worker, s_tool)
	chunk.new_instance = new_instance(chunk.offset, mesh)
	chunk.render_collision = true
	if chunk.render_collision and mesh.get_surface_count():
		chunk.new_instance.create_trimesh_collision()
	chunk.all_air = false
	chunk.has_air = voxels.size() < props.vox_count

func new_instance(offset, mesh):
	var instance = MeshInstance3D.new()
	instance.position = offset
#	instance.use_in_baked_light = true
#	instance.generate_lightmap = true
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	instance.mesh = mesh
	return instance

### Voxel Generation

func add_voxels(chunk:Chunk, vectors:Array=[], voxels:Dictionary={}):
	for vector in vectors:
		add_voxel(chunk, vector, voxels)
	debug_prints(["Voxel count: %3d" % voxels.size(), "\tVector count:", vectors.size()])

func add_voxel(chunk:Chunk, base_pos:Vector3i, voxels:Dictionary={}):
	var scale_pos:Vector3i = base_pos * chunk.scale
	var vox_pos = props.voxlocal(chunk.pos, scale_pos, chunk.depth)
	var color = props.type().get_voxel_color(vox_pos)
	if color.a != 0:
#		if voxels.has(vox_pos): print(vox_pos, ": ", voxels[vox_pos])
		voxels[vox_pos] = Voxel.new(scale_pos, vox_pos, color)
