extends PlanetType

class_name NewPlanetType

func _init(new_props=null):
	pass

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = randi()
		return Color.FOREST_GREEN if rand % 2 else Color.DARK_OLIVE_GREEN

func voxel_is_air(pos:Vector3) -> bool:
	return false

## Gravity Direction
func gravity_dir(pos:Vector3) -> Vector3:
	return Vector3.UP
