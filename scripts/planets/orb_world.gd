extends PlanetType

class_name OrbWorld

func _init(new_props=null):
	._init(new_props)

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = noise.get_noise_3dv(pos)
		var max_height = props.surface_level * props.radius
		var min_height = max_height * 0.5
		var height_range = max_height-min_height
		var water_height = min_height + (height_range*0.60)
		var scale = clamp(((rand + 1) / 2) + .15, 0, 1)
		var height = (height_range * scale) + min_height
		if pos.length() > height:
			if pos.length() < water_height:
				return Color.cornflower
			else:
				return Color(0,0,0,0)
		else:
			if rand >= 0: return Color.forestgreen
			elif rand < 0 and rand > -.25: return Color.cornsilk
			elif rand <= -.25: return Color.cadetblue
			else: return Color.brown

func voxel_is_air(pos:Vector3) -> bool:
	return pos.length() > props.radius * props.surface_level

func test_vox(pos:Vector3) -> bool:
#	print("Test?")
#	return .test_vox(pos)
#	print("Testing for real...")
	var val:float = noise.get_noise_3dv(pos)
	
	var max_height = props.surface_level * props.radius
	var min_height = max_height * 0.5
	var height_range = max_height-min_height
	var water_height = min_height + (height_range*0.60)
	
	var scale = clamp(((val + 1) / 2) + .15, 0, 1)
	var height = (height_range * scale) + min_height
	
	prints(val < props.iso_level, "(", val, "<", props.iso_level, ")")
	if voxel_is_air(pos):
		return false
	else:
		if val < props.iso_level:
			return true
		elif pos.length() > height:
			if pos.length() < water_height:
				return true
			else:
				return false
		else:
			return false

## Gravity Direction
var last_grav = Vector3()
func gravity_dir(pos:Vector3) -> Vector3:
	var grav = (-pos).normalized()
	if grav != last_grav:
#		prints(Vectors.string(pos), "->", Vectors.string(grav))
		last_grav = grav
	return grav
