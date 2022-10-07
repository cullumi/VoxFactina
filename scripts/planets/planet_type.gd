extends Reference

class_name PlanetType

enum AXES {X, Y, Z}
enum {X, Y, Z}

var props

var noise = OpenSimplexNoise.new()

func _init(new_props=null):
	props = new_props
	if props:
		noise = props.noise
	if not noise:
		noise = OpenSimplexNoise.new()
		noise.seed = randi()
		noise.octaves = 8
		noise.period = 100
		noise.persistence = .5
		noise.lacunarity = 2

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = noise.get_noise_3dv(pos)
		return Color.forestgreen if rand <= 0 else Color.darkolivegreen

func voxel_is_air(_pos:Vector3) -> bool:
	return false

## Gravity Direction
func gravity_dir(_pos:Vector3) -> Vector3:
	return Vector3.UP
