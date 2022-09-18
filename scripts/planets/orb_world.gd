extends PlanetType

class_name OrbWorld

func _init(new_props=null):
	._init(new_props)

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = randi()
		return Color.forestgreen if rand % 2 else Color.darkolivegreen

func voxel_is_air(pos:Vector3) -> bool:
	var wr = props.world_radii
	var minimum = min(wr.x, min(wr.y, wr.z))
	var air = pos.length() > minimum * props.surface_level
#	prints(pos, "(", int(pos.length()), ")", "<-->", props.world_radii, "(", minimum, ")", air)
	return air

## Gravity Direction
var last_grav = Vector3()
func gravity_dir(pos:Vector3) -> Vector3:
	var grav = (-pos).normalized()
	if grav != last_grav:
#		prints(Vectors.string(pos), "->", Vectors.string(grav))
		last_grav = grav
	return grav
