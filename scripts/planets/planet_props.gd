extends Resource

class_name PlanetProperties

enum TYPE {ORB, CUBE}
export (TYPE) var planet_type = TYPE.ORB
export (Vector3) var chunk_dims = Vector3(10, 10, 10) setget set_dims
export (Vector3) var chunk_counts:Vector3 = Vector3(3, 3, 3) setget set_counts
export (float, 0, 1, 0.05) var surface_level:float = 0.75 setget set_level
export (float, 0.005, 2, 0.005) var voxel_size:float = 1 setget set_vox_size
export (float, -1, 1, 0.005) var iso_level:float = 0
export (float, EXP, 1000, 1000000, 1000) var voxel_rate:int = 10000
export (SpatialMaterial) var voxel_material
export (OpenSimplexNoise) var noise

# Types
var types = {TYPE.ORB:OrbWorld, TYPE.CUBE:CubeWorld}
var _type:PlanetType
func type():
	if not _type:
		_type = types[planet_type].new(self)
	return _type

func test_vox(val):
	return type().test_vox(val)

# Ranges
var from:Vector3
var to:Vector3
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
func offset(pos:Vector3): # Chunk Position to World Position
#	return Vector3()
#	prints("Center Pos:", center_pos)
#	prints("World Radii:", world_radii)
	return ((pos - center_pos) * chunk_size) - vox_piv
#	var dist_from_center = pos - center_pos
#	var chunk_scaled_dfc = dist_from_center * chunk_size
#	var voxel_shifted_cs_dfc = chunk_scaled_dfc - vox_piv
#	var voxels_per_chunk = chunk_size / voxel_size
#	var voxel_scale_vs_cs_dfc = voxel_shifted_cs_dfc * voxels_per_chunk
#	return voxel_scale_vs_cs_dfc
#	return (((pos - center_pos) * chunk_size) - vox_piv)/chunk_size*voxel_size
func unoffset(off:Vector3): # World Position to Chunk Position
#	return Vector3()
#	print(vox_per_chunk)
	return ((off + vox_piv) / chunk_size) + center_pos
#	var voxel_scale_vs_cs_dfc = off
#	var voxels_per_chunk = chunk_size / voxel_size
#	var voxel_shifted_cs_dfc = voxel_scale_vs_cs_dfc / voxels_per_chunk
#	var chunk_scaled_dfc = voxel_shifted_cs_dfc + vox_piv
#	var dist_from_center = chunk_scaled_dfc / chunk_size
#	var pos = dist_from_center + center_pos
#	return pos
#	return ((((off/voxel_size)*chunk_size)+vox_piv) / chunk_size) + center_pos
func voxoff(c_pos, v_pos):
#	print(v_pos * voxel_size)
#	print(v_pos)
#	return v_pos * voxel_size
#	return v_pos - (chunk_dims/2)
#	prints(chunk_dims, v_pos)
	return ((c_pos-center_pos) * chunk_dims) + v_pos

# Surface Level Rects
var front_radii:Vector2
var top_radii:Vector2
var front:Rect2
var top:Rect2

### Variable Corrections

func set_dims(dims):
	chunk_dims = dims
	from = -chunk_dims/2
	to = chunk_dims/2
	vox_count = chunk_dims.x * chunk_dims.y * chunk_dims.z
	update_world_dims()
	chunk_size = (chunk_dims+Vector3(1,1,1)) * voxel_size

func set_counts(counts):
	chunk_counts = counts
	update_world_dims()
	last_chunk = chunk_counts-Vector3(1,1,1)
	center_chunk = last_chunk/2
	center_pos = center_chunk.floor()

func set_level(level):
	surface_level = level
	update_rects()

func set_vox_size(size):
	voxel_size = size
	chunk_size = (chunk_dims+Vector3(1,1,1)) * voxel_size
	vox_piv = Vector3.ONE * (voxel_size/2)
	vox_per_chunk = chunk_size / voxel_size

func update_world_dims():
	world_dims = chunk_dims * chunk_counts
	world_radii = world_dims/2
	var wr = world_radii
	radius = min(wr.x, min(wr.y, wr.z))
	update_rects()

func update_rects():
	front_radii = Vector2(world_radii.x, world_radii.y) * surface_level
	top_radii = Vector2(world_radii.x, world_radii.z) * surface_level
	front = Rect2(-front_radii, front_radii*2)
	top = Rect2(-top_radii, top_radii*2)
