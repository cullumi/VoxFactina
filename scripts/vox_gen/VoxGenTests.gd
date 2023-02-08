extends Object

class_name Tests


### Chunk Tree

# Verify that every part of the tree is set to be rendered.
static func render_check(root:Chunk) -> bool:
	var _instance_visible = root.instance and root.instance.visible
	if not (root.in_queue or root.in_render or root.is_rendered):
		for child in root.children:
			if not render_check(child):
				return false
	return true

# Check for Non Parent Chunks, print out a peek at where they are.
static func np_chunks_check(chunks, props):
	var np_chunks:Dictionary = {}
	var __chunk:Chunk = null
	for key in chunks.keys():
		__chunk = chunks[key]
		if __chunk.parent == null:
			np_chunks[key] = __chunk
	if not np_chunks.empty():
		print("Some chunks have no parents...")
		Vectors.show_3coords(np_chunks.keys(), props.chunk_counts)

# Print counts from a dictionary of chunk depths.
static func print_chunk_depths(chunk_depths:Dictionary, condensed:bool=false):
	print("Count:")
	for key in chunk_depths.keys():
		prints("\tdepth:", key, "->", chunk_depths[key].size())

# Count lod sizes and compare to octree leaves
static func octree_count(actual:Array, lods:Array, chunks:Dictionary):
	# Comparisons
	print("Comparisons:")
	var sum:int = 0
	for lod in lods:
		sum += lod.values().size()
	prints("\tlods:", actual.size(), "vs", "leaves:", chunks.values().size())
	prints("\tlods:", actual.size(), "vs", "tree:", sum)


### Chunk Rendering

static func leave_trail(source:Node, chunk:Chunk, props):
	if props.DEBUG:
		var cookie:MeshInstance = MeshInstance.new()
		cookie.mesh = CubeMesh.new()
		cookie.mesh.size = Vector3(0.25, 0.25, 0.25)
		var new_mat = SpatialMaterial.new()
		new_mat.albedo_color = props.cookie_material.albedo_color
		new_mat.albedo_color.r = lerp(0, 255, chunk.depth/props.lod_count)
		cookie.material_override = new_mat
		source.add_child(cookie)
		cookie.translation = chunk.offset


### Voxels

# Checks for redundant voxels; really quite slow as the scale of the world increases.
static func voxel_redundancy(vectors, props):
	print("Voxel Redundancy Test")
	var voxels:Dictionary = {}
	var from = props.from
	var to = props.to
	var dif = to - from
	prints("dif:", dif)
	var c_size = props.chunk_dims
	prints("Chunk Count:", props.chunk_counts)
	var origin = -(props.chunk_counts*c_size)/2
	print("Origin:\t", origin, "\nSize:\t", c_size)
	prints(props.from, props.to, "[", props.to-props.from+Vector3.ONE, "]")
	prints(from, to, "[", to-from+Vector3.ONE, "]")
	for c_pos in vectors:
		var start = origin + (c_pos*c_size)
		var end = origin + (c_pos*c_size) + dif
		var pos = start
		while Vectors.lesser(pos, end):
			Count.push(pos, 1, voxels)
			pos = Vectors.count_to(pos, end, start)
		Count.push(pos, 1, voxels)
	print("Counting done")
	var keys = voxels.keys().duplicate()
	var counts:Array = Count.pop_all(true, false, null, voxels)
	for i in range(counts.size()):
		var key = keys[i]
		var count = counts[i]
		if count > 1:
			Count.push(count, 1, voxels)
			prints("Redundant Voxel:", count, "\tof\t", key, "\tfound.")
	Count.pop_all(true, true, null, voxels)
