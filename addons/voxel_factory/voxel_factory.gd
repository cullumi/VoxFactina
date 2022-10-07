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
#var sides:Dictionary = {
#	TOP:[4,5,7,5,6,7],
#	BOTTOM:[1,3,2,1,0,3],
#	RIGHT:[2,5,1,2,6,5],
#	LEFT:[0,7,3,0,4,7],
#	FRONT:[6,2,3,3,7,6],
#	BACK:[0,1,5,5,4,0],
#}
enum {TOP, BOTTOM, 
	  LEFT, RIGHT, 
	  FRONT, BACK
	  
	  TOP_LEFT, TOP_RIGHT, TOP_FRONT, TOP_BACK,
	  BOTTOM_LEFT, BOTTOM_RIGHT, BOTTOM_FRONT, BOTTOM_BACK
	  LEFT_DOWN, LEFT_UP, LEFT_FRONT, LEFT_BACK,
	  RIGHT_DOWN, RIGHT_UP, RIGHT_FRONT, RIGHT_BACK,
	  FRONT_UP, FRONT_DOWN, FRONT_LEFT, FRONT_RIGHT,
	  BACK_UP, BACK_DOWN, BACK_LEFT, BACK_RIGHT
}
#	{LBB=0, RBB=1, RBF=2, LBF=3, LTB=4, RTB=5, RTF=6, LTF=7}
# LBB | RBB
# RBF | LBF
# 
# LTB | RTB
# RTF | LTF
enum {LBB, RBB, RBF, LBF, LTB, RTB, RTF, LTF}
var sides:Dictionary = {
	TOP:[LTB,RTB,LTF,RTB,RTF,LTF],
	BOTTOM:[RBB,LBF,RBF,RBB,LBB,LBF],
	RIGHT:[RBF,RTB,RBB,RBF,RTF,RTB],
	LEFT:[LBB,LTF,LBF,LBB,LTB,LTF],
	FRONT:[RTF,RBF,LBF,LBF,LTF,RTF],
	BACK:[LBB,RBB,RTB,RTB,LTB,LBB],
	
	TOP_LEFT:[]
}

func create_voxel(color, position, voxels=Voxels, s_tool=SurfaceTool):
	voxels = Voxels if voxels == null else voxels
	s_tool = Surfacetool if s_tool == null else s_tool
	
	var left = voxels.get(position - Vector3(1, 0, 0)) == null
	var right = voxels.get(position + Vector3(1, 0, 0)) == null
	var back = voxels.get(position - Vector3(0, 0, 1)) == null
	var front = voxels.get(position + Vector3(0, 0, 1)) == null
	var bottom = voxels.get(position - Vector3(0, 1, 0)) == null
	var top = voxels.get(position + Vector3(0, 1, 0)) == null
	
	var lt = voxels.get(position + Vector3(-1, 1, 0)) != null
	var rt = voxels.get(position + Vector3(1, 1, 0)) != null
	var ft = voxels.get(position + Vector3(0, 1, 1)) != null
	var bt = voxels.get(position + Vector3(0, 1, -1)) != null
	
	var lb = voxels.get(position + Vector3(-1, -1, 0)) != null
	var rb = voxels.get(position + Vector3(1, -1, 0)) != null
	var fb = voxels.get(position + Vector3(0, -1, 1)) != null
	var bb = voxels.get(position + Vector3(0, -1, -1)) != null
	
#	var lft = voxels.get(position + Vector3(-1, 1, 1)) == null
#	var rft = voxels.get(position + Vector3(1, -1, 1)) == null
#	var lbb = voxels.get(position + Vector3(-1, 1, -1)) == null
#	var rbb = voxels.get(position + Vector3(1, -1, -1)) == null
	
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
