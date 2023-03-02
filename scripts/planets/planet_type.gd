extends RefCounted

class_name PlanetType

enum AXES {X, Y, Z}
enum {X, Y, Z}
enum {EXEMPT, AIR, LAND, BEDROCK}

var props

var noise:FastNoiseLite

func _init(new_props=null):
	props = new_props
	if props:
		noise = props.noise
	if not noise:
		noise = FastNoiseLite.new()
		noise.seed = randi()
		noise.fractal_octaves = 8
		noise.frequency = 1.0/100.0
		noise.fractal_gain = .5
		noise.fractal_lacunarity = 2

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = get_density(pos)
		return Color.FOREST_GREEN if rand <= 0 else Color.DARK_OLIVE_GREEN

func voxel_is_air(_pos:Vector3) -> bool:
	return false

func get_density(pos:Vector3) -> float:
	return noise.get_noise_3dv(pos)

func test_vox(_pos:Vector3, density:float=0) -> int:
	return LAND if density <= props.iso_level else AIR

## Gravity Direction
func gravity_dir(_pos:Vector3) -> Vector3:
	return Vector3.UP
