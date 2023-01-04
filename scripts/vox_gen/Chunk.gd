extends Reference

class_name Chunk

var pos:Vector3 = Vector3()
var offset:Vector3 = Vector3()
var size:Vector3 = Vector3()
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
var parent = null

var render_collision:bool = false
var all_air:bool = true
var has_air:bool = false

func _init(props_init, pos_init:Vector3=Vector3(), size_init:Vector3=Vector3(), instance_init:MeshInstance=null, children_init:Array=[]):
	props = props_init
	pos = pos_init
	offset = props.offset(pos)
	size = size_init
	instance= instance_init
	children = children_init

func unrender(trickle_up:bool=false):
	if trickle_up and parent: parent.render()
	if is_rendered and instance:
		instance.visible = false
	return is_rendered

func render(trickle_up:bool=false):
	if trickle_up and parent: parent.unrender()
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

func deform_at(origin:Vector3, depth:int=0, result:Dictionary={}) -> Dictionary:
	if depth > 0:
		for child in children:
			deform_at(origin, depth+1, result)
	else:
		result[depth] = result.get(depth, []).append(self)
	return result

func subdivide():
	var sub_size = size/2
	children.clear()
	children.resize(8)
	for c in range(8):
		c += 1
		var cf = float(c)
		var out = int(not bool(c%2)) * Vector3.BACK
		var up = int(not bool(int(cf/2)%2)) * Vector3.UP
		var right = int(not bool(int(cf/4)%2)) * Vector3.RIGHT
		var change = (out + up + right) * sub_size
		var new_pos = pos+change
		var chunk = get_script().new(props, new_pos, sub_size)
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
