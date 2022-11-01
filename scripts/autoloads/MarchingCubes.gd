extends Node

# Based on Sebastian Lague's "Coding Adventure: Marching Cubes"

var DefaultMaterial = SpatialMaterial.new()
var Surfacetool = SurfaceTool.new()
enum {EXEMPT, AIR, LAND}

func _ready():
	# Making sure that vertex color are used
	DefaultMaterial.vertex_color_use_as_albedo = true
	DefaultMaterial.vertex_color_is_srgb = true
	DefaultMaterial.flags_transparent = true

# Starts the creation of the mesh
func create_mesh(voxels:Dictionary, props, s_tool:SurfaceTool=Surfacetool) -> ArrayMesh:
	assert(s_tool)
	
	s_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if props.voxel_material:
		s_tool.set_material(props.voxel_material)
	else:
		s_tool.set_material(DefaultMaterial)
	
	# Creating the mesh...
	for vox in voxels:
		march(voxels[vox], vox, props, s_tool)

	# Finalise the mesh and return.
	s_tool.index()
	var mesh = s_tool.commit()

	# add meta data to resource for the editor.
	for vox in voxels:
		mesh.set_meta(str(vox), voxels[vox])
	mesh.set_meta("voxel_size", props.voxel_size)
	s_tool.clear()
	return mesh 

# Add voxel to mesh
func march(voxel:Voxel, position:Vector3, props, s_tool:SurfaceTool):
	
	var noise = props.noise
	var vox_size = props.voxel_size
	assert(noise)
	
	# Get The Cube in World Coords
	var offset = voxel.offset - Vector3.ONE*0.5
	var cube_corners:Array = [
		(offset),
		(offset + Vector3(1,0,0)),
		(offset + Vector3(1,0,1)),
		(offset + Vector3(0,0,1)),
		(offset + Vector3(0,1,0)),
		(offset + Vector3(1,1,0)),
		(offset + Vector3(1,1,1)),
		(offset + Vector3(0,1,1)),
	]
	# Get the Cube in Chunk Coords
	var pos = voxel.pos - Vector3.ONE*0.5
	var base_corners:Array = [
		(pos),
		(pos + Vector3(1,0,0)),
		(pos + Vector3(1,0,1)),
		(pos + Vector3(0,0,1)),
		(pos + Vector3(0,1,0)),
		(pos + Vector3(1,1,0)),
		(pos + Vector3(1,1,1)),
		(pos + Vector3(0,1,1)),
	]
	
	# Calculate the index of the current cube configuration as follows:
	#   Loop over each of the 8 corners of the cube.
	#   Set the corresponding bit to 1 if its value is below the surface level.
	#   This will result in a value between 0 and 255.
	var cubeIndex = 0
	for i in range(8):
		var test = props.test_vox(cube_corners[i])
		match test:
			EXEMPT: return
			AIR: pass
			LAND: cubeIndex = cubeIndex + (1 << i)
	
	# Look up triangulation for current cubeIndex.
	# Each entry is the index of an edge.
	var triangulation:Array = TriTable.triangulation[cubeIndex]
	
	# Set a Color
	s_tool.add_color(voxel.color)
	
	var i = -1
	var vertices:Array = []
	for edgeIndex in triangulation:
		if edgeIndex >= 0:
			# Lookup the indices of the corner points making up the current edge
			var indexA:int = TriTable.cornerIndexAFromEdge[edgeIndex]
			var indexB:int = TriTable.cornerIndexBFromEdge[edgeIndex]
			
			# Find midpoint of edge
			var vertexPos:Vector3 = (base_corners[indexA] + base_corners[indexB]) / 2
			
			# Add
			vertices.append(vertexPos*vox_size)
			i = (i+1) % 3
			if i == 2:
#				prints("Add Tri", vertices)
				var prev = vertices[0] - vertices[1]
				var cur = vertices[1] - vertices[2]
				var normal = prev.cross(cur)
				s_tool.add_normal(normal)
				for vertex in vertices:
					s_tool.add_vertex(vertex)
				vertices.clear()

