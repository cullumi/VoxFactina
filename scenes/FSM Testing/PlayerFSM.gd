extends CharacterBody3D

class_name Player

### Properties

## Curves
enum Curves {LINEAR, EXPONENTIAL, INV_S}
var CURVES_DIR = "res://addons/simple_fps_controller/Curves/"
var CURVES_RES = [
	load(CURVES_DIR + "Linear.tres"),
	load(CURVES_DIR + "Exponential.tres"),
	load(CURVES_DIR + "Inverse_S.tres")
]

## Initialization Properties
@export var start_out_flying:bool = false

## Input Properties
@export var mouse_sens = Vector2(.1,.1) # sensitivities for each
@export var gamepad_sens = Vector2(2,2) # axis + input
@export var gamepad_curve = Curves.INV_S # curve analog inputs map to

## Multiplayer Properties
@export var id = 0
@export var mouse_control = true # only works for lowest viewport (first child)

## Movement Properties
# Defaults
@export var move_speed = 7 # max move speed
@export var acceleration = 1 # ground acceleration
@export var air_speed = 7 # max move speed in air
@export var air_acceleration = .5 # air acceleration
@export var jump_speed = 5 # length in frames to reach apex
@export var jump_height = 1 # apex in meters of jump
@export var coyote_factor = 3 # jump forgiveness after leaving platform in frames
@export var gravity_accel = -12 # how fast fall speed increases
@export var gravity_max = -24 # max falling speed
@export var friction = 1.15 # how fast player stops when idle
@export var max_climb_angle = 0.6 # 0.0-1.0 based checked normal of collision .5 for 45 degree slope
@export var angle_of_freedom = 80 # amount player may look up/down
# Flying
@export_range (1, 1000, 1, "exp") var fly_speed:float = 14.0
@export_range (0.1, 10, 1, "exp") var fly_acceleration:float = .5
@export_range (1, 1.5, 1, "exp") var fly_friction:float = 1.15
@export_range (1, 2, 1, "exp") var fly_jump_speed:float = 10.0
@export_range (0, 10, 1, "exp") var fly_jump_height:float = 1.0
# Sprint
@export_range (1, 10, 1, "exp") var sprint_multiplier:float = 14.0

### Nodes
@onready var camera:Camera3D = get_node("%Camera3D")
@onready var collider:CollisionShape3D = get_node("%Collider")
@onready var mv:FSM = get_node("%Movement")
var st_default:NodePath = "%Fall"
var st_jump:NodePath = "%Jump"
enum st {idle, run, jump, fall, floatt, fly, ascend, descend}
var sts:Array = [
	"%Idle", "%Run", "%Jump", "%Fall",
	"%Float", "%Fly",
]
var sts_nodes:Array = []


### Variables
var on_floor:bool = false
var frames:float = 0 # frame jumping
var input_dir:Vector3 = Vector3()
var collision:KinematicCollision3D # Stores the collision from move_and_collide
#var velocity:Vector3 = Vector3()
var coyote_frames:float = 0
var falling = false
var jumping = false
var flying = false


### Events

func _physics_process(delta):
	_process_input(delta)

func _ready():
	# state
	sts_nodes.resize(sts.size())
	for i in range(sts.size()):
		sts_nodes[i] = get_node_or_null(sts[i])
		sts_nodes[i].p = self
	if start_out_flying:
		mv.change_state(sts[st.floatt])
	else:
		mv.change_state(st_default)
	# might need to disable for multiplayer
	if mouse_control: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# mouse movement
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if mouse_control: # only do mouse control if enabled for this instance
			cam_rotate(Vector2(event.relative.x, event.relative.y), mouse_sens)


### Inputs
func _process_input(_delta):
	# Toggle mouse capture
	if Input.is_action_just_pressed("mouse_escape") && mouse_control:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# WASD
	input_dir = Vector3(Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id), 0,
			Input.get_action_strength("back_%s" % id) - Input.get_action_strength("forward_%s" % id)).normalized()
	# Look
	var look_vec = Vector2(
		Input.get_action_strength("look_right_%s" % id) - Input.get_action_strength("look_left_%s" % id),
		Input.get_action_strength("look_down_%s" % id) - Input.get_action_strength("look_up_%s" % id)
	)
	# Map gamepad look to curves
	var signs = Vector2(sign(look_vec.x),sign(look_vec.y))
	var sens_curv = CURVES_RES[gamepad_curve]
	look_vec = look_vec.abs() # Interpolate input checked the curve as positives
	look_vec.x = sens_curv.sample_baked(look_vec.x)
	look_vec.y = sens_curv.sample_baked(look_vec.y)
	look_vec *= signs # Return inputs to original signs
	cam_rotate(look_vec, gamepad_sens)

func _process_grounded_input(_delta):
	# Jump
	if Input.is_action_pressed("jump_%s" % id) && can_jump():
		frames = 0
		mv.change_state(sts[st.jump])
	# Fly
	if Input.is_action_just_pressed("no_clip"):
		mv.change_state(sts[st.floatt])

func _process_flying_input(_delta):
	# Ascend
	var ascend = Input.is_action_pressed("jump_%s" % id)
	var descend = Input.is_action_pressed("crouch")
	input_dir.y = 0 if ascend and descend else (
		-1 if descend else 1 if ascend else 0
	)
	# Ground
	if Input.is_action_just_pressed("no_clip"):
		mv.change_state(sts[st.fall])

### Helpers

## Conversions
func relative(vector:Vector3):
	var formed = global_transform.basis * vector
	var roted = formed.rotated(global_transform.basis.y.normalized(), -rotation.y)
	return roted
func collision_angle(): return global_transform.basis.y.normalized().dot(collision.normal)
func collision_relative(): return relative(collision.normal)

## Collisions
func toggle_general_collision():
	collision_layer = collision_layer ^ 1
	collision_mask = collision_mask ^ 1

## Movement
func air_movement():
	velocity += input_dir.rotated(Vector3(0, 1, 0), rotation.y) * air_acceleration # add acceleration
	if Vector2(velocity.x, velocity.z).length() > air_speed: # clamp speed to max airspeed
		var velocity2d = Vector2(velocity.x, velocity.z).normalized() * air_speed
		velocity.x = velocity2d.x
		velocity.z = velocity2d.y

func apply(delta):
	if velocity.length() >= .5:
		collision = move_and_collide(relative(velocity) * delta)
	else:
		velocity = Vector3(0, velocity.y, 0)
	if collision:
		if collision_angle() < .5: # if collision is 50% not from below aka if checked slope
			velocity.y += delta * gravity_accel
			velocity.y = clamp(velocity.y, gravity_max, 9999)
			velocity = velocity.slide(collision_relative().normalized()).normalized() * velocity.length()

func cam_rotate(vect, sens):
	rotate_y(deg_to_rad(vect.x * sens.y * -1))
	camera.rotate_x(deg_to_rad(vect.y * sens.x * -1))
	
	var camera_rot = camera.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, 90 - angle_of_freedom, 90 + angle_of_freedom)
	camera.rotation_degrees = camera_rot # I don't understand this function

## Inputs
func enable_mouse():
	mouse_control = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## States
func can_jump():
	if not flying:
		if on_floor && not falling && (frames == 0 || frames > jump_speed):
			return true
		elif not jumping && coyote_frames < coyote_factor:
			return true # allows the player to jump after leaving platforms
		else:
			return false
	return false

