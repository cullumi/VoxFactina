extends PlanetType

class_name OrbWorld

var calculated = false
var max_height
var min_height
var height_range
var water_height

func _init(new_props=null):
	._init(new_props)

func t_height(val):
	if not calculated:
		max_height = props.surface_level * props.radius
		min_height = max_height * 0.5
		height_range = max_height-min_height
		water_height = min_height + (height_range*0.60)
		calculated = true
	var scale = clamp(((val + 1) / 2) + .15, 0, 1)
	return (height_range * scale) + min_height

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_in_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = noise.get_noise_3dv(pos)
#		var height = t_height(rand)
		
#		if pos.length() > height:
#			if pos.length() < water_height:
#				return Color.cornflower
#			else:
#				return Color(0,0,0,1)
#		else:
		if rand >= 0: return Color.forestgreen
		elif rand < 0 and rand > -.25: return Color.cornsilk
		elif rand <= -.25: return Color.cadetblue
		else: return Color.brown

func voxel_in_air(pos:Vector3) -> bool:
	return pos.length() > (props.radius * props.surface_level) + props.voxel_size

func voxel_is_air(pos:Vector3) -> bool:
	return pos.length() > props.radius * props.surface_level

func test_vox(pos:Vector3) -> int:
	if voxel_is_air(pos):
		return AIR
	else:
		var val:float = noise.get_noise_3dv(pos)
		var height = t_height(val)
		var length = pos.length()
		
		if length <= height:
			if length <= min_height:
				return LAND
			else:
				return LAND if val < props.iso_level else AIR
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
