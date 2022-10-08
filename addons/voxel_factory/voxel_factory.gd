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
	Vector3(VoxelSize,VoxelSize,VoxelSize), Vector3(0,VoxelSize,VoxelSize)
]

func update_vertices():
	Vertices = [
		Vector3(0,0,0), Vector3(VoxelSize,0,0),
		Vector3(VoxelSize,0,VoxelSize), Vector3(0,0,VoxelSize),
		Vector3(0,VoxelSize,0), Vector3(VoxelSize,VoxelSize,0),
		Vector3(VoxelSize,VoxelSize,VoxelSize), Vector3(0,VoxelSize,VoxelSize) 
	]

# Sides and Normals of a Cube
enum { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }
var normals:Dictionary = {
	TOP:Vector3.UP, BOTTOM:Vector3.DOWN,
	LEFT:Vector3.LEFT, RIGHT:Vector3.RIGHT,
	FRONT:Vector3.FORWARD, BACK:Vector3.BACK,
}
var sides:Dictionary = {
	TOP:[4,5,7,5,6,7],
	BOTTOM:[1,3,2,1,0,3],
	RIGHT:[2,5,1,2,6,5],
	LEFT:[0,7,3,0,4,7],
	FRONT:[6,2,3,3,7,6],
	BACK:[0,1,5,5,4,0],
}

func _ready():
	# Making sure that vertex color are used
	DefaultMaterial.vertex_color_use_as_albedo = true
	DefaultMaterial.vertex_color_is_srgb = true
	DefaultMaterial.flags_transparent = true

# Adds a voxel to the dict.
func add_voxel(position, color, voxels=Voxels):
	if color.a != 0:
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
func create_voxel(color:Color, position:Vector3, voxels:Dictionary=Voxels, s_tool:SurfaceTool=Surfacetool):
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
		add_vertices(TOP, position, s_tool)
	if right:
		add_vertices(RIGHT, position, s_tool)
	if left:
		add_vertices(LEFT, position, s_tool)
	if front:
		add_vertices(FRONT, position, s_tool)
	if back:
		add_vertices(BACK, position, s_tool)
	if bottom:
		add_vertices(BOTTOM, position, s_tool)

func add_vertices(side:int, position:Vector3, s_tool:SurfaceTool=Surfacetool):
	s_tool.add_normal(normals[side])
	for vert in sides[side]:
		s_tool.add_vertex(Vertices[vert] + position * VoxelSize)
