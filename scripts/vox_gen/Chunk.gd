extends RefCounted

class_name Chunk

var pos:Vector3i = Vector3()
var offset:Vector3 = Vector3()
var scale:Vector3i = Vector3i()
var new_instance:MeshInstance3D = null
var instance:MeshInstance3D = null

var priority:int = 0
var in_render:bool = false
var is_rendered:bool = false
var in_queue:bool = false
var next
var prev

var props
var worker:Worker

var children:Array = []
var parent:Chunk = null
var depth:int = 0
var tree_height:int = 0
var deform_on_finish:bool = false

var render_collision:bool = false
var all_air:bool = true
var has_air:bool = false
var deformed:bool = false

# Debugging
var debug_mask:Node
var debug_origin:Node

func _init(_props,_pos:Vector3=Vector3(),_scale:Vector3=Vector3(),_depth:int=0,_tree=null,_instance:MeshInstance3D=null,_children:Array=[]):
	props = _props
	pos = _pos
	scale = _scale
	depth = _depth
	if props:
		tree_height = props.lod_count
		offset = props.offset(pos, depth)
	instance = _instance
	children = _children
	if (props):
		init_debug_mask()

func init_debug_mask():
	debug_mask = MeshInstance3D.new()
	debug_mask.scale = scale
	debug_mask.mesh = BoxMesh.new()
	debug_mask.material_override = props.debug_material
	debug_mask.mesh.size = props.chunk_size

func height():
	return tree_height - depth - 1

func unrender():
	if is_rendered and instance:
		instance.visible = false
	return is_rendered

func finish_render(source:Node) -> Array:
	if instance != new_instance:
		if instance != null: 
			instance.queue_free()
		instance = new_instance
		if instance != null:
			assert(instance.mesh != null)
			if instance.mesh.get_surface_count() > 0:
				source.add_child(instance)
				instance.visible = true
				if props.DEBUG:
					if debug_mask.get_parent():
						debug_mask.reparent(instance)
			else:
				Count.push("0_surface")
	in_render = false
	is_rendered = true
	return [] if not parent else parent.deform()

### Subdivision & Deformation

func children_rendered():
	for child in children:
		if not child.is_rendered:
			return false
	return true

func deform() -> Array:
	if children.is_empty():
		print("Something wasn't subdivided")
		subdivide()
	if children_rendered():
		var _res = unrender()
		return []
	else:
		var _result:Array = []
		for child in children:
			if not (child.is_rendered or child.in_queue or child.in_render):
				_result.append(child)
		return _result

func deform_at(origin:Vector3, result:Dictionary={}) -> Dictionary:
	assert(depth < props.lod_ranges.size())
	var distance = props.lod_ranges[depth]
	var def_check:bool = not deformed
	var depth_check:bool = depth < tree_height-1
	var dist_check:bool = close_enough(origin, distance)
	if def_check and depth_check and dist_check:
		if children.is_empty():
			subdivide()
		deformed = true
		for child in children:
			if not child.deformed:
				var _result = child.deform_at(origin, result)
				if not child.deformed:
					deformed = false
	else:
		result[depth] = result.get(depth, [])
		result[depth].append(self)
		if depth >= tree_height:
			deformed = true
	return result

func close_enough(origin:Vector3, distance:float) -> bool:
	var aabb:AABB = AABB(pos, scale)
	var intersect_point:Vector3 = origin.move_toward(pos, distance)
	var intersects = aabb.intersects_segment(origin, intersect_point)
	return intersects != null

func subdivide():
	assert(scale >= Vector3i.ONE)
	var sub_scale:Vector3i = scale/2
	children.clear()
	children.resize(8)
	for c in range(8):
		c += 1
		var cf = float(c)
		var out:Vector3i = int(not bool(c%2)) * Vector3i.BACK
		var up:Vector3i = int(not bool(int(cf/2)%2)) * Vector3i.UP
		var right:Vector3i = int(not bool(int(cf/4)%2)) * Vector3i.RIGHT
		var change = (out + up + right) * sub_scale
		var new_pos = pos+change
		var chunk = get_script().new(props, new_pos, sub_scale, depth+1)
		chunk.parent = self
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
