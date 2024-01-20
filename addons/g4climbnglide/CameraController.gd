extends Node3D

@export var follow_object:NodePath
@export var basis_target:NodePath
@export var follow_speed:float
@export var invertX:bool = false
@export var invertY:bool = false
@export var actions:Actions

@onready var follow:Node3D = get_node(follow_object)
@onready var orient:Node3D = get_node(basis_target)

var mousev:Vector2
var joyv:Vector2
var mouse:bool

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mousev += Input.get_last_mouse_velocity()*0.00001
		mouse = true
	elif event is InputEventJoypadMotion:
		joyv = Actions.vector(actions.look) * 0.1


func _physics_process(delta):
	var velocity = mousev if mouse else joyv
	if mouse:
		mouse = false
		mousev = Vector2()
	
	rotate_y(velocity.x if invertX else velocity.x*-1)
	rotate_object_local(Vector3.LEFT,(velocity.y if invertY else velocity.y*-1))
	rotation.x = clamp(rotation.x, -15, 15)
	if follow != null:
		var goto = follow.position+Vector3(0,1,0)
		position = position + ((goto-position)*delta*follow_speed)
