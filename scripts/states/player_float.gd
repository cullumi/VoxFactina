class_name Float # Replace this with your state's name
extends State


# player and finite state machine
@onready var p:Player
@onready var mv:FSM = get_node("%Movement")

@onready var st_fall:NodePath = "%Fall"
@onready var st_fly:NodePath = "%Fly"
@onready var st_ascend:NodePath = "%Ascend"
@onready var st_descend:NodePath = "%Fall"


# Called when a state enters the finite state machine
func _enter_state():
	p.flying = true
	p.toggle_general_collision()
#	p.collider.disabled = true


# Called every frame by the finite state machine's process method
func _process_state(_delta: float):
	pass


# Called every frame by the finite state machine's physics process method
func _physics_process_state(delta: float):
	# Input
	p._process_flying_input(delta)
	
	# State Management
	if p.collision:
		if p.collision_angle() >= p.max_climb_angle:
			p.on_floor = true
			p.coyote_frames = 0
	if p.input_dir.length() > .1 && (p.frames > p.jump_speed || p.frames == 0):
		mv.change_state(st_fly)
	
	# Float
	if p.frames < p.jump_speed:
		p.frames += 1 * delta * 60
	elif p.velocity.length() > .5:
		p.velocity /= p.friction
		if p.collision:
			var rel_vel = p.relative(p.velocity)
			var rel_xz = rel_vel - (rel_vel * p.collision.normal.abs().normalized())
			var rel_adj = ((rel_xz.dot(p.collision.normal)) * -1) - .0001
			p.velocity.y = -rel_adj
	
	# Apply
	p.apply(delta)


# Called when a state exits the finite state machine
func _exit_state():
	p.flying = false
	p.toggle_general_collision()
