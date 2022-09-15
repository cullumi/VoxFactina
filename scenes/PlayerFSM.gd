extends KinematicBody

class_name PlayerFSM

### Properties

## Curves
enum Curves {LINEAR, EXPONENTIAL, INV_S}
var CURVES_DIR = "res://addons/simple_fps_controller/Curves/"
var CURVES_RES = [
	load(CURVES_DIR + "Linear.tres"),
	load(CURVES_DIR + "Exponential.tres"),
	load(CURVES_DIR + "Inverse_S.tres")
]

## Input Properties
export var mouse_sens = Vector2(.1,.1) # sensitivities for each
export var gamepad_sens = Vector2(2,2) # axis + input
export var gamepad_curve = Curves.INV_S # curve analog inputs map to

## Multiplayer Properties
export var id = 0
export var mouse_control = true # only works for lowest viewport (first child)

## Movement Properties
# Defaults
export var move_speed = 7 # max move speed
export var acceleration = 1 # ground acceleration
export var air_speed = 7 # max move speed in air
export var air_acceleration = .5 # air acceleration
export var jump_speed = 5 # length in frames to reach apex
export var jump_height = 1 # apex in meters of jump
export var coyote_factor = 3 # jump forgiveness after leaving platform in frames
export var gravity_accel = -12 # how fast fall speed increases
export var gravity_max = -24 # max falling speed
export var friction = 1.15 # how fast player stops when idle
export var max_climb_angle = 0.6 # 0.0-1.0 based on normal of collision .5 for 45 degree slope
export var angle_of_freedom = 80 # amount player may look up/down
# Flying
export (float, EXP, 1, 1000) var fly_speed = 14
export (float, EXP, 0.1, 10) var fly_acceleration = .5
export (float, 1, 1.5) var fly_friction = 1.15
export (float, EXP, 1, 1000) var fly_jump_speed = 10
export (float, EXP, 1, 10) var fly_jump_height = 1
# Sprint
export (float, EXP, 1, 10) var sprint_multiplier = 14
# Non-Flight
onready var standard_jump_speed = jump_speed
onready var standard_jump_height = jump_height
onready var standard_speed = air_speed
onready var standard_acceleration = fly_acceleration


### Nodes
onready var camera = get_node("%Camera")
onready var mv:FSM = get_node("%Movement")
var st_default:NodePath = "%PlayerFall"
var st_jump:NodePath = "%PlayerJump"
var sts:Array = [
	"%PlayerIdle", "%PlayerFall", "%PlayerFly", "%PlayerJump", "%PlayerRun"
]


### Variables
var on_floor:bool = false
var frames:float = 0 # frame jumping
var input_dir:Vector3 = Vector3()
var collision:KinematicCollision # Stores the collision from move_and_collide
var velocity:Vector3 = Vector3()
var coyote_frames:float = 0
var falling = false
var jumping = false


### Events

func _physics_process(delta):
	_process_input(delta)

func _ready():
	# state
	for i in range(sts.size()):
		sts[i] = get_node_or_null(sts[i])
		sts[i].p = self
	mv.change_state(st_default)
	# might need to disable for multiplayer
	if mouse_control: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# mouse movement
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if mouse_control: # only do mouse control if enabled for this instance
			cam_rotate(Vector2(event.relative.x, event.relative.y), mouse_sens)


### Inputs
func _process_input(delta):
	# Toggle mouse capture
	if Input.is_action_just_pressed("mouse_escape") && mouse_control:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Jump
	if Input.is_action_pressed("jump_%s" % id) && can_jump():
		frames = 0
		mv.change_state(st_jump)
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
	look_vec = look_vec.abs() # Interpolate input on the curve as positives
	look_vec.x = sens_curv.interpolate_baked(look_vec.x)
	look_vec.y = sens_curv.interpolate_baked(look_vec.y)
	look_vec *= signs # Return inputs to original signs
	cam_rotate(look_vec, gamepad_sens)


### Helpers

## Conversions
func relative(vector:Vector3):
	var formed = global_transform.basis.xform(velocity)
	var roted = formed.rotated(global_transform.basis.y.normalized(), -rotation.y)
	return roted
func collision_angle(): return global_transform.basis.y.normalized().dot(collision.normal)
func collision_relative(): return relative(collision.normal)

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
		if collision_angle() < .5: # if collision is 50% not from below aka if on slope
			velocity.y += delta * gravity_accel
			clamp(velocity.y, gravity_max, 9999)
			velocity = velocity.slide(collision_relative().normalized()).normalized() * velocity.length()
		else:
			velocity = velocity

func cam_rotate(vect, sens):
	rotate_y(deg2rad(vect.x * sens.y * -1))
	camera.rotate_x(deg2rad(vect.y * sens.x * -1))
	
	var camera_rot = camera.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, 90 - angle_of_freedom, 90 + angle_of_freedom)
	camera.rotation_degrees = camera_rot # I don't understand this function

## Inputes
func enable_mouse():
	mouse_control = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## States
func can_jump():
	if on_floor && not falling && (frames == 0 || frames > jump_speed):
		return true
	elif not jumping && coyote_frames < coyote_factor:
		return true # allows the player to jump after leaving platforms
	else:
		return false

