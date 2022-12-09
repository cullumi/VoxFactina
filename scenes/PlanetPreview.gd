tool

extends MeshInstance

class_name PlanetPreview

export (bool) var redraw = false setget do_redraw

func do_redraw(_val):
	redraw = false
	draw()

func _enter_tree():
	if not Engine.editor_hint:
		return
	draw()

# Only works if the parent is a Planet containing PlanetProperties and a PlanetType.
func draw():
	if mesh: mesh = null
	
	var parent = get_parent()
	if not parent is Planet: return
	
	var props:PlanetProperties = parent.props as PlanetProperties
	if not props: return
	elif not props.is_connected("changed", self, "draw"):
		var _res := props.connect("changed", self, "draw")
	
	if props.planet_type == props.TYPE.CUBE:
		var cube := CubeMesh.new()
		mesh = cube
		cube.size = props.world_dims * props.voxel_size
	else:
		var sphere := SphereMesh.new()
		mesh = sphere
		sphere.radius = props.world_radii.x * props.voxel_size
		sphere.height = props.world_dims.y * props.voxel_size
