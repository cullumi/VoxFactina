extends Reference

class_name Chunk

var pos:Vector3 = Vector3()
var offset:Vector3 = Vector3()
var scale:Vector3 = Vector3()
var new_instance:MeshInstance = null
var instance:MeshInstance = null

var priority:int = 0
var in_render:bool = false
var is_rendered:bool = false
var in_queue:bool = false
var next
var prev

var props

var children:Array = []
var parent:Chunk = null
var depth:int = 0

var render_collision:bool = false
var all_air:bool = true
var has_air:bool = false

func _init(_props, _pos:Vector3=Vector3(), _scale:Vector3=Vector3(), _depth:int=0, _instance:MeshInstance=null, _children:Array=[]):
	props = _props
	pos = _pos
	offset = props.offset(pos)
	scale = _scale
	depth = _depth
	instance= _instance
	children = _children

func unrender(trickle_up:bool=false):
	if trickle_up and parent: parent.render(true)
	if is_rendered and instance:
		instance.visible = false
	return is_rendered

func render(trickle_up:bool=false):
	if trickle_up and parent: parent.unrender(true)
	if is_rendered and instance:
		instance.visible = true
	return is_rendered

func finish_render(source:Node):
	if instance != new_instance:
		if instance != null: 
			instance.queue_free()
		instance = new_instance
		if instance != null:
			assert(instance.mesh != null)
			if instance.mesh.get_surface_count() > 0:
				source.add_child(instance)
			else:
				Count.push("0_surface")
#				source.add_child(instance)
	render(true)
	in_render = false
	is_rendered = true

### Subdivision & Deformation

func deform_to(depth:int) -> Array:
	if depth > 0:
		var result:Array = []
		for child in children:
			result.append_array(deform_to(depth-1))
		return result
	else:
		return [self]

func deform_at(origin:Vector3, ranges:Array, result:Dictionary={}) -> Dictionary:
	if not children.empty() and close_enough(origin, ranges[depth]):
		for child in children:
			var _result = child.deform_at(origin, ranges, result)
	else:
		result[depth] = result.get(depth, [])
		result[depth].append(self)
	return result

func close_enough(origin:Vector3, distance:float):
	var aabb:AABB = AABB(pos, scale)
#	prints(origin.distance_to(pos), "<", ranges[depth])
	var intersect_point:Vector3 = origin.move_toward(pos, distance)
#	prints(origin, "->", pos, "=", intersect_point, "(" + String(aabb) + ")")
	return aabb.intersects_segment(origin, intersect_point)

func subdivide():
	var sub_scale = scale/2
	children.clear()
	children.resize(8)
	for c in range(8):
		c += 1
		var cf = float(c)
		var out = int(not bool(c%2)) * Vector3.BACK
		var up = int(not bool(int(cf/2)%2)) * Vector3.UP
		var right = int(not bool(int(cf/4)%2)) * Vector3.RIGHT
		var change = (out + up + right) * sub_scale
		var new_pos = pos+change
		var chunk = get_script().new(props, new_pos, sub_scale, depth+1)
		children[c-1] = chunk
	return children
	
	# -
	# out
	# up
	# up out
	# right
	# right out
	# right up
	# right up out
