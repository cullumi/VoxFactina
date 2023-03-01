extends PlanetType

class_name OrbWorld

var calculated = false
var max_height
var min_height
var height_range
var water_height

func _init(new_props=null):
	super._init(new_props)

func init_height():#val):
	if not calculated:
		max_height = props.surface_level * props.radius
		min_height = max_height * props.bedrock_level
		height_range = max_height-min_height
		water_height = min_height + (height_range*0.60)
		calculated = true

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_in_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = noise.get_noise_3dv(pos)
		if rand >= 0: return Color.FOREST_GREEN
		elif rand < 0 and rand > -.25: return Color.CORNSILK
		elif rand <= -.25: return Color.CADET_BLUE
		else: return Color.BROWN

func voxel_in_air(pos:Vector3) -> bool:
	init_height()
	return pos.length() > (props.radius * props.surface_level) + props.voxel_size

func voxel_is_air(pos:Vector3) -> bool:
	init_height()
	return pos.length() > props.radius * props.surface_level

func test_vox(pos:Vector3, density:float=0) -> int:
#	return LAND if density < props.iso_level else AIR
	if voxel_is_air(pos):
		return AIR
	else:
		init_height()
		var length = pos.length()
		var air_height_scale = clamp(((density + 1) / 2) + .05, 0, 1)
		var air_height = (height_range * air_height_scale) + min_height
		var height_percent = length/max_height
		if length <= min_height:
			return BEDROCK
		elif length <= air_height:
			var iso = (props.iso_curve.sample(height_percent)*2)-1
			return LAND if density < iso else AIR
		else:
			return AIR

## Gravity Direction
var last_grav = Vector3()
func gravity_dir(pos:Vector3) -> Vector3:
	var grav = (-pos).normalized()
	if grav != last_grav:
#		prints(Vectors.string(pos), "->", Vectors.string(grav))
		last_grav = grav
	return grav
