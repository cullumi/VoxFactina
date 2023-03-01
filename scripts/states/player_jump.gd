class_name Jump # Replace this with your state's name
extends State

@onready var p:Player
@onready var mv:FSM = get_node("%Movement")

@onready var st_fall:NodePath = "%Fall"

# Called when a state enters the finite state machine
func _enter_state():
	p.jumping = true
#	print("Jump")

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
	else:
		p.on_floor = false # fixes wall climbing due to walls having y1 normal sometimes
		p.coyote_frames = p.coyote_factor + 1

	# Jump
	if p.frames < p.jump_speed:
		p.velocity.y = p.jump_height/(p.jump_speed * delta)
		p.frames += 1 * delta * 60
	else:
		mv.change_state(st_fall)

	# Air Movement
	p.air_movement()

	# Apply
	p.apply(delta)


# Called when a state exits the finte state machine
func _exit_state():
	p.jumping = false
