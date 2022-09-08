extends Node
#tool
# ------ Voxel Factory -----
#
# I recommend putting this script in your autoloads
# You can them access the factory by doing : 
# 	onready var VoxelFactory = get_node("/root/VoxelFactory")
#
# After that you have access to the factory through this node.
# For exemple:
#	self.mesh = VoxelFactory.create_mesh_from_image_file("res://icon.png")
#
# Thank you for downloading Voxel factory.
# If you need help you can message me on the discord: 
#                                                     @Kreptic
var VoxelSize = 1.0
var DefaultMaterial = SpatialMaterial.new()
var Voxels = {} # Data in the factory
var Surfacetool = SurfaceTool.new()

# Vertices of a cube
var Vertices = [
	Vector3(0,0,0), Vector3(VoxelSize,0,0),
	Vector3(VoxelSize,0,VoxelSize), Vector3(0,0,VoxelSize),
	Vector3(0,VoxelSize,0), Vector3(VoxelSize,VoxelSize,0),
	Vector3(VoxelSize,VoxelSize,VoxelSize), Vector3(0,VoxelSize,VoxelSize) ]

func update_vertices():
	Vertices = [
		Vector3(0,0,0), Vector3(VoxelSize,0,0),
		Vector3(VoxelSize,0,VoxelSize), Vector3(0,0,VoxelSize),
		Vector3(0,VoxelSize,0), Vector3(VoxelSize,VoxelSize,0),
		Vector3(VoxelSize,VoxelSize,VoxelSize), Vector3(0,VoxelSize,VoxelSize) 
	]

func _ready():
	# Making sure that vertex color are used
	DefaultMaterial.vertex_color_use_as_albedo = true
	DefaultMaterial.vertex_color_is_srgb = true
	DefaultMaterial.flags_transparent = true

# Adds a voxel to the dict.
func add_voxel(position, color, voxels=Voxels):
	if color.a == 0:
		return
	else:
		voxels = Voxels if voxels == null else voxels
		voxels[position] = color

func clear_voxels(voxels=Voxels):
	if voxels != null:
		voxels.clear()

# From image file.
func create_mesh_from_image_file(path, voxels=Voxels, s_tool=Surfacetool) -> Mesh:
	var image = Image.new()
	image.load(path)
	return create_mesh_from_image(image, voxels, s_tool)

# From image data-type
func create_mesh_from_image(image, voxels=Voxels, s_tool=Surfacetool) -> Mesh:
	voxels = Voxels if voxels == null else voxels
	voxels.clear()
	var imageSize = image.get_size()
	
	# Image is upside down by default.
	image.flip_y()
	image.lock()
	
	# For each pixel add a voxel.
	for x in imageSize.x:
		for y in imageSize.y:
			add_voxel(Vector3(x, y, 0), image.get_pixel(x, y), voxels)
	
	image.unlock()
	return create_mesh(voxels, s_tool)


# Starts the creation of the mesh
func create_mesh(voxels=Voxels, s_tool=Surfacetool) -> ArrayMesh:
	voxels = Voxels if voxels == null else voxels
	s_tool = Surfacetool if s_tool == null else s_tool
	
	s_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	DefaultMaterial.vertex_color_use_as_albedo = true
	DefaultMaterial.vertex_color_is_srgb = true
	DefaultMaterial.flags_vertex_lighting = true
	DefaultMaterial.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
	DefaultMaterial.metallic = 0.25
	DefaultMaterial.roughness = 0.75
	s_tool.set_material(DefaultMaterial)
	
	# Creating the mesh...
	for vox in voxels:
		create_voxel(voxels[vox], vox, voxels, s_tool)

	# Finalise the mesh and return.
	s_tool.index()
	var mesh = s_tool.commit()

	# add meta data to resource for the editor.
	for vox in voxels:
		mesh.set_meta(str(vox), voxels[vox])
	mesh.set_meta("voxel_size", VoxelSize)
	s_tool.clear()
	return mesh 

# Decides where to put faces on the mesh.
# Checks if there is an adjacent block before place a face.
func create_voxel(color, position, voxels=Voxels, s_tool=SurfaceTool):
	voxels = Voxels if voxels == null else voxels
	s_tool = Surfacetool if s_tool == null else s_tool
	
	var left = voxels.get(position - Vector3(1, 0, 0)) == null
	var right = voxels.get(position + Vector3(1, 0, 0)) == null
	var back = voxels.get(position - Vector3(0, 0, 1)) == null
	var front = voxels.get(position + Vector3(0, 0, 1)) == null
	var bottom = voxels.get(position - Vector3(0, 1, 0)) == null
	var top = voxels.get(position + Vector3(0, 1, 0)) == null
	
	# Stop if the block is completly hidden.
	if(!left and !right and !top and !bottom and !front and !back):
		return
	
	s_tool.add_color(color)
	
	if top:
		s_tool.add_normal(Vector3.UP)
		s_tool.add_vertex(Vertices[4] + position * VoxelSize)
		s_tool.add_vertex(Vertices[5] + position * VoxelSize)
		s_tool.add_vertex(Vertices[7] + position * VoxelSize)
		s_tool.add_vertex(Vertices[5] + position * VoxelSize)
		s_tool.add_vertex(Vertices[6] + position * VoxelSize)
		s_tool.add_vertex(Vertices[7] + position * VoxelSize)
	if right:
		s_tool.add_normal(Vector3.RIGHT)
		s_tool.add_vertex(Vertices[2] + position * VoxelSize)
		s_tool.add_vertex(Vertices[5] + position * VoxelSize)
		s_tool.add_vertex(Vertices[1] + position * VoxelSize)
		s_tool.add_vertex(Vertices[2] + position * VoxelSize)
		s_tool.add_vertex(Vertices[6] + position * VoxelSize)
		s_tool.add_vertex(Vertices[5] + position * VoxelSize)
	if left:
		s_tool.add_normal(Vector3.LEFT)
		s_tool.add_vertex(Vertices[0] + position * VoxelSize)
		s_tool.add_vertex(Vertices[7] + position * VoxelSize)
		s_tool.add_vertex(Vertices[3] + position * VoxelSize)
		s_tool.add_vertex(Vertices[0] + position * VoxelSize)
		s_tool.add_vertex(Vertices[4] + position * VoxelSize)
		s_tool.add_vertex(Vertices[7] + position * VoxelSize)
	if front:
		s_tool.add_normal(Vector3.FORWARD)
		s_tool.add_vertex(Vertices[6] + position * VoxelSize)
		s_tool.add_vertex(Vertices[2] + position * VoxelSize)
		s_tool.add_vertex(Vertices[3] + position * VoxelSize)
		s_tool.add_vertex(Vertices[3] + position * VoxelSize)
		s_tool.add_vertex(Vertices[7] + position * VoxelSize)
		s_tool.add_vertex(Vertices[6] + position * VoxelSize)
	if back:
		s_tool.add_normal(Vector3.BACK)
		s_tool.add_vertex(Vertices[0] + position * VoxelSize)
		s_tool.add_vertex(Vertices[1] + position * VoxelSize)
		s_tool.add_vertex(Vertices[5] + position * VoxelSize)
		s_tool.add_vertex(Vertices[5] + position * VoxelSize)
		s_tool.add_vertex(Vertices[4] + position * VoxelSize)
		s_tool.add_vertex(Vertices[0] + position * VoxelSize)
	if bottom:
		s_tool.add_normal(Vector3.DOWN)
		s_tool.add_vertex(Vertices[1] + position * VoxelSize)
		s_tool.add_vertex(Vertices[3] + position * VoxelSize)
		s_tool.add_vertex(Vertices[2] + position * VoxelSize)
		s_tool.add_vertex(Vertices[1] + position * VoxelSize)
		s_tool.add_vertex(Vertices[0] + position * VoxelSize)
		s_tool.add_vertex(Vertices[3] + position * VoxelSize)
