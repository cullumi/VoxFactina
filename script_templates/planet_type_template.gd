extends Reference

class_name PlanetType

func _init(new_props=null):
	pass

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return Color(0,0,0,0)
	else:
		var rand = randi()
		return Color.forestgreen if rand % 2 else Color.darkolivegreen

func voxel_is_air(pos:Vector3) -> bool:
	return false

## Gravity Direction
func gravity_dir(pos:Vector3) -> Vector3:
	return Vector3.UP
