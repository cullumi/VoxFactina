@tool

extends MeshInstance3D

class_name PlanetPreview

@export var redraw:bool = false : set = do_redraw

var props:PlanetProperties

func do_redraw(_val):
	redraw = false
	draw()

func _enter_tree():
	if Engine.is_editor_hint():
		connect_props()
		if props:
			draw()

func connect_props():
	var parent = get_parent()
	if parent is Planet:
		props = parent.props
	if props and not props.changed.is_connected(draw):
		props.changed.connect(draw)

# Only works if the parent is a Planet containing PlanetProperties and a PlanetType.
func draw():
	assert(props)
	match props.planet_type:
		props.TYPE.CUBE:
			var cube := BoxMesh.new()
			cube.size = props.world_dims * props.voxel_size
			mesh = cube
		_:
			var sphere := SphereMesh.new()
			sphere.radius = props.world_radii.x * props.voxel_size
			sphere.height = props.world_dims.y * props.voxel_size
			mesh = sphere