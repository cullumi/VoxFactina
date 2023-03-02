extends Resource

class_name Actions

@export var move_front:String = "forward" :
	get: return get_idxed(move_front)
@export var move_back:String = "backward" :
	get: return get_idxed(move_back)
@export var move_left:String = "left" :
	get: return get_idxed(move_left)
@export var move_right:String = "right" :
	get: return get_idxed(move_right)

@export var look_up:String = "look_up" :
	get: return get_idxed(look_up)
@export var look_down:String = "look_down" :
	get: return get_idxed(look_down)
@export var look_left:String = "look_left" :
	get: return get_idxed(look_left)
@export var look_right:String = "look_right" :
	get: return get_idxed(look_right)

@export var crouch:String = "crouch" :
	get: return get_idxed(crouch)
@export var jump:String = "jump" :
	get: return get_idxed(jump)
@export var toggle_fly:String = "toggle_fly" :
	get: return get_idxed(toggle_fly)
@export var dash:String = "dash" :
	get: return get_idxed(dash)

var move:Array[String] : 
	get: return [move_right, move_left, move_back, move_front]
var look:Array[String] :
	get: return [look_left, look_right, look_up, look_down]

@export_range(0, 3) var idx:int = 0
func get_idxed(action:String):
	if Engine.is_editor_hint(): return action
	else: return action + "_" + str(idx)

static func pressed(action:String):
	return Input.is_action_just_pressed(action)
static func down(action:String):
	return Input.is_action_pressed(action)
static func released(action:String):
	return Input.is_action_just_released(action)
static func strength(action:String):
	return Input.get_action_strength(action)
static func vector(actions:Array[String]):
	return Input.get_vector.callv(actions)
