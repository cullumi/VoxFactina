extends Object

class_name Octree

var root:Chunk = null
var lods:Array = []
var lod_nodes:Array = []

func depth(props):
	var width:int = props.chunk_counts.x
	var depth = 1
	while (width > 1):
		depth += 1
		width /= 2
	return depth + 2

func create(props, deform_pos:Vector3) -> Dictionary:
	
	# Initials
	var pos:Vector3 = Vector3()
	var scale:Vector3 = props.chunk_counts# * props.chunk_size
	var level = 0
	
	# 1st LOD
	lods = []
	for l in range(props.lod_count):
		lods.append({})
	var root_lod = lods.front()
	root = Chunk.new(props, pos, scale, 0, 0)
	root_lod[pos] = root
	var leaves = root.deform_at(deform_pos)
	return leaves

func save_lods(chunk:Chunk):
	lods[chunk.depth][chunk.pos] = chunk
	if not chunk.children.empty():
		for child in chunk.children:
			save_lods(child)

	# Child LODs
#	while Vectors.any_greater(scale, Vector3.ONE):
#		lods.append({})
#		level += 1
#		scale /= 2
#		var plod = lods[level-1]
#		lod = lods[level]
#		for key in plod.keys():
#			var chunk:Chunk = plod[key]
#			chunk.subdivide()
#			for child in chunk.children:
#				lod[child.pos] = child
#
#	return lods
