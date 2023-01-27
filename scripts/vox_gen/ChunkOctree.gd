extends Object

class_name Octree

static func depth(props):
	var width:int = props.chunk_counts.x
	var depth = 1
	while (width > 1):
		depth += 1
		width /= 2
	return depth + 2

static func create(props):
	
	# Initials
	var pos:Vector3 = Vector3()
	var scale:Vector3 = props.chunk_counts# * props.chunk_size
	var level = 0
	
	# 1st LOD
	var lods = [{}]
	var lod = lods[level]
	lod[pos] = Chunk.new(props, pos, scale)
	
	# Child LODs
	while Vectors.any_greater(scale, Vector3.ONE):
		lods.append({})
		level += 1
		scale /= 2
		var plod = lods[level-1]
		lod = lods[level]
		for key in plod.keys():
			var chunk:Chunk = plod[key]
			chunk.subdivide()
			for child in chunk.children:
				lod[child.pos] = child
	
	return lods
