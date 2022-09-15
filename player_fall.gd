class_name PlayerFall # Replace this with your state's name
extends State

onready var p = $"."
onready var mv:FSM = get_node("%Movement")

onready var st_idle:NodePath = "%PlayerIdle"
onready var st_run:NodePath = "%PlayerRun"

# Called when a state enters the finite state machine
func _enter_state():
	p.falling = true


# Called every frame by the finite state machine's process method
func _process_state(delta: float):
	pass


# Called every frame by the finite state machine's physics process method
func _physics_process_state(delta: float):
	# State Management
	if !p.collision:
		p.on_floor = false
		p.coyote_frames += 1 * delta * 60
	else:
		if p.collision_angle() >= p.max_climb_angle:
			p.on_floor = true
			p.coyote_frames = 0
			if p.input_dir.length() > .1 && (p.frames > p.jump_speed || p.frames == 0):
				mv.change_state(st_run)
			else:
				mv.change_state(st_idle)
	
	# Fall
	p.velocity.y += p.gravity_accel * delta * 4
	p.velocity.y = clamp(p.velocity.y, p.gravity_max, 9999)

	# Air Movement
	p.air_movement()

	# Apply
	p.apply(delta)


# Called when a state exits the finte state machine
func _exit_state():
	p.falling = false
