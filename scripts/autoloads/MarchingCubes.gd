extends Node

# Based on Sebastian Lague's "Coding Adventure: Marching Cubes"

var VoxelSize = 2
var IsoLevel = 0.0
var DefaultMaterial = SpatialMaterial.new()
var Surfacetool = SurfaceTool.new()

func _ready():
	# Making sure that vertex color are used
	DefaultMaterial.vertex_color_use_as_albedo = true
	DefaultMaterial.vertex_color_is_srgb = true
	DefaultMaterial.flags_transparent = true

# Starts the creation of the mesh
func create_mesh(voxels:Dictionary, props, s_tool:SurfaceTool=Surfacetool, iso_level:float=IsoLevel, vox_size:float=VoxelSize) -> ArrayMesh:
	assert(s_tool)
	
	s_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if props.voxel_material:
		s_tool.set_material(props.voxel_material)
	else:
		s_tool.set_material(DefaultMaterial)
	
	# Creating the mesh...
	for vox in voxels:
		march(voxels[vox], vox, props, s_tool, vox_size, iso_level)

	# Finalise the mesh and return.
	s_tool.index()
	var mesh = s_tool.commit()

	# add meta data to resource for the editor.
	for vox in voxels:
		mesh.set_meta(str(vox), voxels[vox])
	mesh.set_meta("voxel_size", VoxelSize)
	s_tool.clear()
	return mesh 

# Add voxel to mesh
func march(color:Color, position:Vector3, props, s_tool:SurfaceTool, vox_size:float, iso_level:float):
	
	var noise = props.noise
	assert(noise)
	
	# Get The Cube
	var cube_corners:Array = [
		position,
		position + (Vector3(1,0,0)),
		position + (Vector3(1,0,1)),
		position + (Vector3(0,0,1)),
		position + (Vector3(0,1,0)),
		position + (Vector3(1,1,0)),
		position + (Vector3(1,1,1)),
		position + (Vector3(0,1,1)),
	]
	var cube_vals:Array = [
		noise.get_noise_3dv(cube_corners[0]),
		noise.get_noise_3dv(cube_corners[1]),
		noise.get_noise_3dv(cube_corners[2]),
		noise.get_noise_3dv(cube_corners[3]),
		noise.get_noise_3dv(cube_corners[4]),
		noise.get_noise_3dv(cube_corners[5]),
		noise.get_noise_3dv(cube_corners[6]),
		noise.get_noise_3dv(cube_corners[7]),
	]
#	var cube_positions:Array = [
#		cube_corners[0], cube_corners[1],
#		cube_corners[2], cube_corners[3],
#		cube_corners[4], cube_corners[5],
#		cube_corners[6], cube_corners[7],
#	]
	
	# Calculate the index of the current cube configuration as follows:
	#   Loop over each of the 8 corners of the cube.
	#   Set the corresponding bit to 1 if its value is below the surface level.
	#   This will result in a value between 0 and 255.
#	iso_level = -0
	var cubeIndex = 0
	for i in range(8):
#		if cube_vals[i] < iso_level:
		if props.test_vox(cube_corners[i]):
			cubeIndex = cubeIndex + (1 << i)
	
	# Look up triangulation for current cubeIndex.
	# Each entry is the index of an edge.
	var triangulation:Array = TriTable.triangulation[cubeIndex]
	
	# Set a Color
	s_tool.add_color(color)
	
	var rand = int(rand_range(0, 50))
	prints(rand, "| Adding:", position, "<-", "idx:", cubeIndex)
	prints(rand, "| vals:", cube_vals)
	var vertices:Array = []
	for edgeIndex in triangulation:
		if edgeIndex >= 0:
			# Lookup the indices of the corner points making up the current edge
			var indexA:int = TriTable.cornerIndexAFromEdge[edgeIndex]
			var indexB:int = TriTable.cornerIndexBFromEdge[edgeIndex]
			
			# Find midpoint of edge
			var vertexPos:Vector3 = (cube_corners[indexA] + cube_corners[indexB]) / 2
			
#			prints(rand, "|", vertexPos, "<-", "idx:", edgeIndex, "[", indexA, "/", indexB, "]")
			vertices.append(vertexPos)
	
	var normals:Array = []
	var i = 0
	var last:Vector3
	var prev_vector:Vector3
	for vertex in vertices:
		i = (i+1) % 3
		match i:
			0: last = vertex
			1: prev_vector = last-vertex
			2: normals.append(prev_vector.cross(last-vertex))
	
	for n in range(normals.size()):
		s_tool.add_normal(-normals[n])
#		prints(rand, "|", normals[n])
		for v in range(3):
			var vertex = vertices[(n*3)+v]
			s_tool.add_vertex(vertex*vox_size)

