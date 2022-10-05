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
		var height = max_height * ((rand + 1) / 2)
		if pos.length() > height:
			if pos.length() < max_height/2:
				return Color.cornflower
			else:
				return Color(0,0,0,0)
		else:
			return Color.forestgreen if rand >= 0 else Color.darkolivegreen

func voxel_is_air(pos:Vector3) -> bool:
	return pos.length() > props.radius * props.surface_level

## Gravity Direction
var last_grav = Vector3()
func gravity_dir(pos:Vector3) -> Vector3:
	var grav = (-pos).normalized()
	if grav != last_grav:
#		prints(Vectors.string(pos), "->", Vectors.string(grav))
		last_grav = grav
	return grav
