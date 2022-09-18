extends PlanetType

class_name CubeWorld

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
