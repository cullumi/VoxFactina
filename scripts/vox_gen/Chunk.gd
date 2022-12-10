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

var children:Array = []
var parent = null

var render_collision:bool = false
var all_air:bool = true
var has_air:bool = false

func _init(pos_init:Vector3=Vector3(), offset_init:Vector3=Vector3(), size_init:Vector3=Vector3(), instance_init:MeshInstance=null, children_init:Array=[]):
	pos = pos_init
	offset = offset_init
	size_init
	instance= instance_init
	children = children_init

func unrender(trickle_up:bool=false):
	if trickle_up and parent: parent.render()
	if is_rendered:
		assert(instance)
		instance.visible = false
	return is_rendered

func render(trickle_up:bool=false):
	if trickle_up and parent: parent.unrender()
	if is_rendered:
		assert(instance)
		instance.visible = true
	return is_rendered

func finish_render(source:Node):
	if instance != new_instance:
		if instance != null: 
			instance.queue_free()
		instance = new_instance
		if instance != null:
			assert(instance.mesh != null)
#			assert(chunk.instance.mesh.get_surface_count())
			source.add_child(instance) 
	render(true)
	in_render = false
	is_rendered = true

func subdivide():
	var sub_size = size/2
	children.clear()
	children.resize(8)
	for c in range(8):
		c += 1
		var out = int(not bool(c%2)) * Vector3.FORWARD
		var up = int(not bool((c/2)%2)) * Vector3.UP
		var right = int(not bool((c/4)%2)) * Vector3.RIGHT
		var change = out + up + right
		var chunk = get_script().new(pos+change, offset+(sub_size*change), sub_size)
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
