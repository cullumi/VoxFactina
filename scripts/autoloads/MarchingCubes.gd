extends Node

# Based checked Sebastian Lague's "Coding Adventure: Marching Cubes"
# https://www.youtube.com/watch?v=M3iI2l0ltbE
# https://github.com/SebLague/Marching-Cubes/blob/master/Assets/Scripts/Compute/MarchingCubes.compute

var DefaultMaterial = StandardMaterial3D.new()
var Surfacetool = SurfaceTool.new()
enum {EXEMPT, AIR, LAND, BEDROCK}

func _ready():
	# Making sure that vertex color are used
	DefaultMaterial.vertex_color_use_as_albedo = true
	DefaultMaterial.vertex_color_is_srgb = true
	DefaultMaterial.flags_transparent = true

# Starts the creation of the mesh
func create_mesh(scale:Vector3, voxels:Dictionary, props:PlanetProperties, worker:Worker=null, s_tool:SurfaceTool=Surfacetool) -> ArrayMesh:
	
	assert(s_tool)
	s_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if props.voxel_material:
		s_tool.set_material(props.voxel_material)
	else:
		s_tool.set_material(DefaultMaterial)
	
	# Creating the mesh...
	var corner_tests:Dictionary = {} # For reusing corner tests between voxels
#	print("Creating Mesh...")
	for vox in voxels:
		march(scale, voxels[vox], props, s_tool, corner_tests, worker)

	# Finalise the mesh and return.
	s_tool.index()
	var mesh = s_tool.commit()

	# add meta data to resource for the editor.
	for vox in voxels:
		var meta_name = Vectors.to_meta_name(vox)
		mesh.set_meta(meta_name, voxels[vox])
	mesh.set_meta("voxel_size", props.voxel_size)
	
#	print("Marching cubes: %3d" % voxels.size(), "\tVoxel size: %3d" % props.voxel_size)
	
	s_tool.clear()
	return mesh 

# Add voxel to mesh
func march(scale:Vector3, voxel:Voxel, props:PlanetProperties, s_tool:SurfaceTool, c_tests:Dictionary, worker:Worker=null):
	
	var debug:bool = scale.x > 32
	if debug: print(scale)
	var noise = props.noise
	var offset_scale = scale #Vector3.ONE #scale #props.offset(scale)
	var vox_size = props.voxel_size
	scale = scale #Vectors.clamp_to(scale/64, Vector3.ONE, Vector3.ONE*1000) #Vector3.ONE
	assert(noise)
	
	# Get The Cube in World3D Coords
	var offset = voxel.offset - offset_scale*0.5
	var cube_corners:Array = [
		(offset),
		(offset + (Vector3(1,0,0) * offset_scale)),
		(offset + (Vector3(1,0,1) * offset_scale)),
		(offset + (Vector3(0,0,1) * offset_scale)),
		(offset + (Vector3(0,1,0) * offset_scale)),
		(offset + (Vector3(1,1,0) * offset_scale)),
		(offset + (Vector3(1,1,1) * offset_scale)),
		(offset + (Vector3(0,1,1) * offset_scale)),
	]
	# Get the Cube in Chunk Coords
	var pos = Vector3(voxel.pos) - scale*0.5
	var base_corners:Array = [
		(pos),
		(pos + Vector3(1,0,0) * scale),
		(pos + Vector3(1,0,1) * scale),
		(pos + Vector3(0,0,1) * scale),
		(pos + Vector3(0,1,0) * scale),
		(pos + Vector3(1,1,0) * scale),
		(pos + Vector3(1,1,1) * scale),
		(pos + Vector3(0,1,1) * scale),
	]
	
	var base_densities:Array = [
		props.get_density(cube_corners[0]),
		props.get_density(cube_corners[1]),
		props.get_density(cube_corners[2]),
		props.get_density(cube_corners[3]),
		props.get_density(cube_corners[4]),
		props.get_density(cube_corners[5]),
		props.get_density(cube_corners[6]),
		props.get_density(cube_corners[7]),
	]
	
	# Calculate the index of the current cube configuration as follows:
	#   Loop over each of the 8 corners of the cube.
	#   Set the corresponding bit to 1 if its value is below the surface level.
	#   This will result in a value between 0 and 255.
	var cubeIndex = 0
	for i in range(8):
		var result = c_tests.get(cube_corners[i]) # Avoids recomputation
		if result == null:
			result = props.test_vox(cube_corners[i], base_densities[i])
			c_tests[cube_corners[i]] = result
		else:
			pass
		match result:
			EXEMPT: return
			AIR: base_densities[i] = -1000
			BEDROCK: cubeIndex = cubeIndex + (1 << i)
			LAND: cubeIndex = cubeIndex + (1 << i)
	
	# Look up triangulation for current cubeIndex.
	# Each entry is the index of an edge.
	if worker: worker.mutex.lock()
	var triangulation:Array = TriTable.triangulation[cubeIndex].duplicate()
	if worker: worker.mutex.unlock()
	
	# Set a Color
	s_tool.set_color(voxel.color)
	
	var i = -1
	var vertices:Array = []
	for edgeIndex in triangulation:
		if edgeIndex >= 0:
			# Lookup the indices of the corner points making up the current edge
#			push_warning("Corner Lookup (", voxel, ")")
			assert(edgeIndex < TriTable.cornerIndexAFromEdge.size() and edgeIndex < TriTable.cornerIndexBFromEdge.size())
			if worker: worker.mutex.lock()
			var indexA:int = TriTable.cornerIndexAFromEdge[edgeIndex]
			var indexB:int = TriTable.cornerIndexBFromEdge[edgeIndex]
			if worker: worker.mutex.unlock()
			
			# Densities, for convenience
#			push_warning("Density Lookup (", voxel, ")")
			var d1:float = base_densities[indexA]
			var d2:float = base_densities[indexB]
			
			# Find midpoint of edge
			var mid_vertexPos:Vector3 = (base_corners[indexA] + base_corners[indexB]) / 2
			# Find interpolation of edge
			var int_vertexPos:Vector3
			if d1 != d2:
				var v1:Vector3 = base_corners[indexA]
				var v2:Vector3 = base_corners[indexB]
#				prints("Interpolate:", "\n\tv1:", v1, "\n\tv2:", v2, "\n\td1:", d1, "d1:", d2, "iso:", props.iso_level)
				int_vertexPos = interpolate_vertices(v1, v2, d1, d2, props.iso_level)
#				prints("Midpoint vs Interpolation:", mid_vertexPos, "vs", int_vertexPos)
			else:
				pass
#				prints("Not Interpolated");
			
			var vertexPos
			if d1 < -1 or d2 < -1 or d1 == d2:
				vertexPos = mid_vertexPos
			else:
				vertexPos = int_vertexPos
			
			vertexPos = int_vertexPos#mid_vertexPos
			
			# Add
			vertices.append(vertexPos*vox_size)
			i = (i+1) % 3
			if i == 2:
#				prints("Add Tri", vertices)
				var prev:Vector3 = vertices[0] - vertices[1]
				var cur:Vector3 = vertices[1] - vertices[2]
				var normal:Vector3 = prev.cross(cur).normalized()
				if not normal.is_normalized():
					normal = Vector3.UP
				assert(normal.is_normalized())
				s_tool.set_normal(normal)
				for vertex in vertices:
					s_tool.add_vertex(vertex)
				vertices.clear()

# Midpoint Formula
func midpoint_vertices(v1:Vector3, v2:Vector3):
	return (v1 + v2)/2

# Interpolates based checked two vertices and their densities, considering the iso level.
func interpolate_vertices(v1:Vector3, v2:Vector3, d1:float, d2:float, iso_level:float):
	var t = (iso_level - d1) / (d2 - d1)
	return v1 + (t * (v2 - v1))
