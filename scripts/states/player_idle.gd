class_name Idle # Replace this with your state's name
extends State

# player and finite state machine
@onready var p:Player
@onready var mv:FSM = get_node("%Movement")

# other states to change to
@onready var st_fall:NodePath = "%Fall"
@onready var st_run:NodePath = "%Run"

# Called when a state enters the finite state machine
func _enter_state():
	pass

# Called every frame by the finite state machine's process method
func _process_state(_delta: float):
	pass

# Called every frame by the finite state machine's physics process method
func _physics_process_state(delta: float):
	# Input
	p._process_grounded_input(delta)
	
	# State Management
	if !p.collision:
		p.on_floor = false
		p.coyote_frames += 1 * delta * 60
		mv.change_state(st_fall)
	elif p.collision_angle() < p.max_climb_angle:
		mv.change_state(st_fall)
	else:
		p.on_floor = true
		p.coyote_frames = 0
		if p.input_dir.length() > .1 && (p.frames > p.jump_speed || p.frames == 0):
			mv.change_state(st_run)
	
	# Idle
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

# Called when a state exits the finte state machine
func _exit_state():
	pass
