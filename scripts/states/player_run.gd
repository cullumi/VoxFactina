class_name Run # Replace this with your state's name
extends State

onready var p:Player
onready var mv:FSM = get_node("%Movement")

onready var st_fall:NodePath = "%Fall"
onready var st_idle:NodePath = "%Idle"

# Called when a state enters the finite state machine
func _enter_state():
	print("Run")

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
	else:
		if p.collision_angle() < p.max_climb_angle:
			mv.change_state(st_fall)
		else:
			p.on_floor = true
			p.coyote_frames = 0
			if p.input_dir.length() <= .1 || (p.frames <= p.jump_speed && p.frames != 0):
				mv.change_state(st_idle)
	
	# Run
	p.velocity += p.input_dir.rotated(Vector3(0, 1, 0), p.rotation.y) * p.acceleration
	if Vector2(p.velocity.x, p.velocity.z).length() > p.move_speed:
		p.velocity = p.velocity.normalized() * p.move_speed # clamp move speed
	if p.collision:
		var rel_vel = p.relative(p.velocity)
		var rel_xz = rel_vel - (rel_vel * p.collision.normal.abs().normalized())
		var rel_adj = ((rel_xz.dot(p.collision.normal)) * -1)
		p.velocity.y = -rel_adj
	
	# fake gravity to keep character on the ground
	# increase if player is falling down slopes instead of running
	p.velocity.y -= .0001 + (int(p.velocity.y < 0) * 1.1)

	# Apply
	p.apply(delta)

# Called when a state exits the finte state machine
func _exit_state():
	pass
