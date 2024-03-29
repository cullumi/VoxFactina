tool

extends Resource

class_name PlanetProperties

enum TYPE {ORB, CUBE}
export (TYPE) var planet_type = TYPE.ORB
export (Vector3) var chunk_dims = Vector3(10, 10, 10) setget set_dims
export (Vector3) var chunk_counts:Vector3 = Vector3(3, 3, 3) setget set_counts
export (float, 0, 1, 0.05) var surface_level:float = 0.75 setget set_surface
export (float, 0, 1, 0.05) var bedrock_level:float = 0.15 setget set_bedrock
export (float, 0.005, 2, 0.005) var voxel_size:float = 1 setget set_vox_size
export (float, -1, 1, 0.005) var iso_level:float = 0
export (Curve) var iso_curve:Curve
export (float, EXP, 1000, 1000000, 1000) var voxel_rate:int = 10000
export (SpatialMaterial) var voxel_material
export (OpenSimplexNoise) var noise
export (bool) var DEBUG
export (SpatialMaterial) var debug_material
export (SpatialMaterial) var cookie_material

# Types
var types = {TYPE.ORB:OrbWorld, TYPE.CUBE:CubeWorld}
var _type:PlanetType
func type():
	if not _type:
		_type = types[planet_type].new(self)
	return _type

func get_density(pos:Vector3) -> float:
	return type().get_density(pos)

func test_vox(pos:Vector3, density:float=0) -> int:
	return type().test_vox(pos, density)

# LODs
var lod_ranges:Array
var lod_count:int

# Ranges
var from:Vector3
var to:Vector3
var relative_voxel_positions:Array = []
var vox_count:int

# Dimensions
var world_dims:Vector3
var world_radii:Vector3
var chunk_size:Vector3
var radius:float
var vox_per_chunk:Vector3

# Locations
var last_chunk:Vector3
var center_chunk:Vector3
var center_pos:Vector3

# Offsets
var vox_piv:Vector3
func centered(pos:Vector3):
	return pos - center_pos
func half_chunk() -> Vector3: return chunk_size/2
func lod_adj(depth) -> Vector3:
	return Vector3.ONE * (0.5 if depth%2==0 else 0.0)
func lod_inv(depth) -> Vector3:
	return Vector3.ONE * (0.5 if depth%2==1 else 0.0)

func offset(pos:Vector3, lod_depth:int=0) -> Vector3: # Chunk Position to World Position
	return (centered(pos) - lod_adj(lod_depth)) * chunk_size
func unoffset(off:Vector3) -> Vector3: # World Position to Chunk Position
	return ((off + half_chunk()) / chunk_size) + center_pos
func voxlocal(c_pos:Vector3, v_pos:Vector3, lod:int=0) -> Vector3: # Voxel Chunk Position to Voxel World Position
	return (centered(c_pos) + lod_inv(lod)) * chunk_dims + v_pos

# Surface Level Rects
var front_radii:Vector2
var top_radii:Vector2
var front:Rect2
var top:Rect2

# Updates
func signal_update(should_signal:bool=true):
	if should_signal:
		emit_signal("changed")

### Variable Corrections

func set_dims(dims, should_signal:bool=true):
	chunk_dims = dims
	from = -chunk_dims/2
	to = (chunk_dims/2)-Vector3.ONE
	relative_voxel_positions = Vectors.collect_vectors(from, to)
	vox_count = chunk_dims.x * chunk_dims.y * chunk_dims.z
	update_world_dims(false)
	chunk_size = chunk_dims * voxel_size
	signal_update(should_signal)

func set_counts(counts, should_signal:bool=true):
	chunk_counts = counts
	prints("set counts:", chunk_counts)
	update_lod_ranges(false)
	update_world_dims(false)
	last_chunk = chunk_counts-Vector3(1,1,1)
	center_chunk = last_chunk/2
	center_pos = center_chunk.floor()
	signal_update(should_signal)

func set_surface(level, should_signal:bool=true):
	surface_level = level
	update_rects(false)
	signal_update(should_signal)

func set_bedrock(level, should_signal:bool=true):
	bedrock_level = level
	update_rects(false)
	signal_update(should_signal)

func set_vox_size(size, should_signal:bool=true):
	voxel_size = size
	chunk_size = chunk_dims * voxel_size
	vox_piv = Vector3.ONE * (voxel_size/2)
	vox_per_chunk = chunk_size / voxel_size
	signal_update(should_signal)

func update_lod_ranges(should_signal:bool=true):
	prints("lod ranges:", chunk_counts.x, chunk_dims.x)
	lod_ranges = [(chunk_counts.x * chunk_dims.x) / 2]
	lod_count = int(log(chunk_counts.x)/log(2))
	for _l in range(lod_count):
		lod_ranges.append(lod_ranges.back() / 2)
	prints("Lod Ranges:", lod_ranges)
	signal_update(should_signal)

func update_world_dims(should_signal:bool=true):
	world_dims = chunk_dims * chunk_counts
	world_radii = world_dims/2
	var wr = world_radii
	radius = min(wr.x, min(wr.y, wr.z))
	update_rects(false)
	signal_update(should_signal)

func update_rects(should_signal:bool=true):
	front_radii = Vector2(world_radii.x, world_radii.y) * surface_level
	top_radii = Vector2(world_radii.x, world_radii.z) * surface_level
	front = Rect2(-front_radii, front_radii*2)
	top = Rect2(-top_radii, top_radii*2)
	signal_update(should_signal)
