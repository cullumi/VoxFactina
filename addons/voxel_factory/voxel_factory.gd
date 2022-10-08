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

func _init():
	init_normals()

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
#	TOP:[LTB,RTB,LTF,RTB,RTF,LTF],
#	BOTTOM:[RBB,LBF,RBF,RBB,LBB,LBF],
#	RIGHT:[RBF,RTB,RBB,RBF,RTF,RTB],
#	LEFT:[LBB,LTF,LBF,LBB,LTB,LTF],
#	FRONT:[RTF,RBF,LBF,LBF,LTF,RTF],
#	BACK:[LBB,RBB,RTB,RTB,LTB,LBB],
#}
enum {
	# Square Sides
	TOP, BOTTOM, 
	LEFT, RIGHT, 
	FRONT, BACK
	# Triangle Sides
	TOP_SLANT_0, TOP_SLANT_1, TOP_SLANT_2, TOP_SLANT_3,
	BOTTOM_SLANT_0, BOTTOM_SLANT_1, BOTTOM_SLANT_2, BOTTOM_SLANT_3
	LEFT_SLANT_0, LEFT_SLANT_1, LEFT_SLANT_2, LEFT_SLANT_3,
	RIGHT_SLANT_0, RIGHT_SLANT_1, RIGHT_SLANT_2, RIGHT_SLANT_3,
	FRONT_SLANT_0, FRONT_SLANT_1, FRONT_SLANT_2, FRONT_SLANT_3,
	BACK_SLANT_0, BACK_SLANT_1, BACK_SLANT_2, BACK_SLANT_3,
	# Slopes
	SLOPE_DL_UR, SLOPE_UL_DR,
	SLOPE_DF_UB, SLOPE_UF_DB,
	SLOPE_FL_BR, SLOPE_BL_FR,
}

func slopes(one, two):
	for key in slopes.keys():
		var ops:Array = slopes[key]
		for op in ops:
			if op.has(one) and op.has(two):
				return key
	return -1

var slopes:Dictionary = {
	SLOPE_DL_UR:[[TOP,LEFT],[BOTTOM,RIGHT]],
	SLOPE_UL_DR:[[TOP,RIGHT],[BOTTOM,LEFT]],
	
	SLOPE_DF_UB:[[TOP,FRONT], [BOTTOM,BACK]],
	SLOPE_UF_DB:[[TOP,BACK], [BOTTOM,FRONT]],
	
	SLOPE_FL_BR:[[FRONT,RIGHT], [BACK,LEFT]],
	SLOPE_BL_FR:[[FRONT,LEFT], [BACK,RIGHT]],
}
var normals:Dictionary = {
	# Sides
	TOP:Vector3.UP, BOTTOM:Vector3.DOWN,
	LEFT:Vector3.LEFT, RIGHT:Vector3.RIGHT,
	FRONT:Vector3.FORWARD, BACK:Vector3.BACK,
	# Slopes
	SLOPE_DL_UR:[TOP,LEFT], SLOPE_UL_DR:[TOP,RIGHT],
	SLOPE_DF_UB:[TOP,FRONT], SLOPE_UF_DB:[TOP,BACK],
	SLOPE_FL_BR:[FRONT,RIGHT], SLOPE_BL_FR:[FRONT,LEFT],
}
func init_normals():
	for key in normals.keys():
		var val = normals[key]
		if val is Array:
			normals[key] = Vector3.ZERO
			for side in val:
				normals[key] += normals[side]
			normals[key] = normals[key].normalized()
#	{LBB=0, RBB=1, RBF=2, LBF=3, LTB=4, RTB=5, RTF=6, LTF=7}
# LBB | RBB
# RBF | LBF
# 
# LTB | RTB
# RTF | LTF
#enum {LBB, RBB, RBF, LBF, LTB, RTB, RTF, LTF}
var sides:Dictionary = {
	TOP:[4,5,7,5,6,7],
	BOTTOM:[1,3,2,1,0,3],
	RIGHT:[2,5,1,2,6,5],
	LEFT:[0,7,3,0,4,7],
	FRONT:[6,2,3,3,7,6],
	BACK:[0,1,5,5,4,0],
	
	TOP_SLANT_0:[4,5,7], TOP_SLANT_1:[5,6,7],
	TOP_SLANT_2:[4,5,6], TOP_SLANT_3:[4,6,7],
	
	BOTTOM_SLANT_0:[1,3,2], BOTTOM_SLANT_1:[1,0,3],
	BOTTOM_SLANT_2:[0,3,2], BOTTOM_SLANT_3:[0,2,1],
	
	LEFT_SLANT_0:[0,7,3], LEFT_SLANT_1:[0,4,7],
	LEFT_SLANT_2:[4,3,0], LEFT_SLANT_3:[4,7,3],
	
	RIGHT_SLANT_0:[2,5,1], RIGHT_SLANT_1:[2,6,5],
	RIGHT_SLANT_2:[6,1,2], RIGHT_SLANT_3:[6,5,1],
	
	FRONT_SLANT_0:[6,2,3], FRONT_SLANT_1:[3,7,6],
	FRONT_SLANT_2:[2,3,7], FRONT_SLANT_3:[2,7,6],
	
	BACK_SLANT_0:[0,1,5], BACK_SLANT_1:[5,4,0],
	BACK_SLANT_2:[4,5,1], BACK_SLANT_3:[4,1,0],
	
	SLOPE_DL_UR:[0,6,3, 0,5,6], SLOPE_UL_DR:[2,7,4, 2,4,1],
	SLOPE_DF_UB:[2,4,3, 2,5,4], SLOPE_UF_DB:[6,0,1, 6,7,1],
	SLOPE_FL_BR:[7,1,3, 7,5,1], SLOPE_BL_FR:[6,2,0, 6,0,4],
}

func create_voxel(color:Color, position:Vector3, voxels:Dictionary=Voxels, s_tool:SurfaceTool=Surfacetool):
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
		for vert in sides[TOP]:
			s_tool.add_vertex(Vertices[vert] + position * VoxelSize)
	if right:
		s_tool.add_normal(Vector3.RIGHT)
		for vert in sides[RIGHT]:
			s_tool.add_vertex(Vertices[vert] + position * VoxelSize)
	if left:
		s_tool.add_normal(Vector3.LEFT)
		for vert in sides[LEFT]:
			s_tool.add_vertex(Vertices[vert] + position * VoxelSize)
	if front:
		s_tool.add_normal(Vector3.FORWARD)
		for vert in sides[FRONT]:
			s_tool.add_vertex(Vertices[vert] + position * VoxelSize)
	if back:
		s_tool.add_normal(Vector3.BACK)
		for vert in sides[BACK]:
			s_tool.add_vertex(Vertices[vert] + position * VoxelSize)
	if bottom:
		s_tool.add_normal(Vector3.DOWN)
		for vert in sides[BOTTOM]:
			s_tool.add_vertex(Vertices[vert] + position * VoxelSize)

func add_vertices(side:int, position:Vector3, s_tool:SurfaceTool=Surfacetool):
	s_tool.add_normal(normals[side])
	for vert in sides[side]:
		s_tool.add_vertex(Vertices[vert] + position + VoxelSize)
