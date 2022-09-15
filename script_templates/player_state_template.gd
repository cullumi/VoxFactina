class_name PlayerTemplateState # Replace this with your state's name
extends State


# player and finite state machine
onready var p:Player
onready var mv:FSM = get_node("%Movement")

# other states to change to
var st_fall:NodePath = "%PlayerFall"
var st_run:NodePath = "%PlayerRun"


# Called when a state enters the finite state machine
func _enter_state():
	pass


# Called every frame by the finite state machine's process method
func _process_state(_delta: float):
	pass


# Called every frame by the finite state machine's physics process method
func _physics_process_state(delta: float):
	# Input
	# State Management
	# Idle
	# Apply
	pass


# Called when a state exits the finte state machine
func _exit_state():
	pass
