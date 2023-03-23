extends Node

#class_name Tests

var show_debug:bool = false

### Chunk Tree

# Verify that every part of the tree is set to be rendered.
func render_check(root:Chunk) -> bool:
	var _instance_visible = root.instance and root.instance.visible
	if not (root.in_queue or root.in_render or root.is_rendered):
		for child in root.children:
			if not render_check(child):
				push_warning("Chunk failed render check")
				return false
	return true

# Check for Non Parent Chunks, print out a peek at where they are.
func np_chunks_check(chunks:Dictionary, props:PlanetProperties):
	var np_chunks:Dictionary = {}
	var _chunk:Chunk = null
	for key in chunks.keys():
		_chunk = chunks[key]
		if _chunk.parent == null:
			np_chunks[key] = _chunk
	if not np_chunks.is_empty():
		push_warning("Some chunks have no parents...")
		print("Some chunks have no parents...")
		Vectors.show_3coords(np_chunks.keys(), props.chunk_counts)

# Print counts from a dictionary of chunk depths.
func print_chunk_depths(chunk_depths:Dictionary):
	if not show_debug: return
	print("Count:")
	for key in chunk_depths.keys():
		prints("\tdepth:", key, "->", chunk_depths[key].size())

# Count lod sizes and compare to octree leaves
func octree_count(actual:Array, lods:Array, chunks:Dictionary):
	if not show_debug: return
	print("Comparisons:")
	var sum:int = 0
	for lod in lods:
		sum += lod.values().size()
	var tsum:int = 0
	for l in range(lods.size()+1): # 16 -> 8 -> 4 -> 2 -> 1
		tsum += int(pow(int(pow(2, l)), 3))
	prints("\tlods:", actual.size(), "vs", "leaves:", chunks.values().size())
	prints("\tlods:", actual.size(), "vs", "tree:", sum)
	prints("\tlods:", actual.size(), "vs", "full tree:", tsum)


### Chunk Rendering

func repeated(object, cache:Dictionary):
	if not cache.get(object, false):
		cache[object] = true
		print("New chunk: ", object, " (", cache.size(), ")")
	else:
		print("Repeat chunk. (", cache.size(), ")")

func leave_trail(source:Node, chunk:Chunk, props):
	if props.DEBUG:
		var cookie:MeshInstance3D = MeshInstance3D.new()
		cookie.mesh = BoxMesh.new()
		cookie.mesh.size = Vector3(0.25, 0.25, 0.25)
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = props.cookie_material.albedo_color
		new_mat.albedo_color.r = lerp(0, 255, chunk.depth/props.lod_count)
		cookie.material_override = new_mat
		source.add_child(cookie)
		cookie.position = chunk.offset


### Voxels

# Checks for redundant voxels; really quite slow as the scale of the world increases.
func voxel_redundancy(vectors, props):
	if not show_debug: return
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
