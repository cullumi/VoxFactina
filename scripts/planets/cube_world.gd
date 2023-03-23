extends PlanetType

class_name CubeWorld

func _init(new_props=null):
	super._init(new_props)

## Content Queries
func get_voxel_color(pos:Vector3) -> Color:
	if voxel_is_air(pos):
		return AIR
	else:
		var rand = get_density(pos)
		var max_height = props.surface_level * props.radius
		var height = max_height * ((rand + 1) / 2)
		if pos.length() > height:
			if pos.length() < max_height/2:
				return Color.CORNFLOWER_BLUE
			else:
				return AIR
		else:
			return Color.FOREST_GREEN if rand >= 0 else Color.DARK_OLIVE_GREEN

func voxel_is_air(pos:Vector3) -> bool:
	var in_front = props.front.has_point(Vector2(pos.x, pos.y))
	var in_top = props.top.has_point(Vector2(pos.x, pos.z))
	return not in_front or not in_top

## Gravity Direction
func gravity_dir(pos:Vector3) -> Vector3:
	var norm = pos.normalized().abs()
	var axis = X if norm.x > norm.y else Y
	axis = axis if norm[axis] > norm.z else Z
	var final = Vector3()
	final[axis] = -sign(pos[axis])
	if final == Vector3():
		return Vector3.UP
	else:
		return final
