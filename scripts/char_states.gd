extends Reference

class_name PlayerState

enum {
	STATE_WALKING, STATE_LEANING, STATE_CROUCHING,
	STATE_CRAWLING, STATE_CLAMBERING_RISE, STATE_NOCLIP,
	STATE_CLAMBERING_LEDGE, STATE_CLAMBERING_VENT, 
}

var States = {
	STATE_WALKING:Walk, STATE_LEANING:Lean, STATE_CROUCHING:Crouch,
	STATE_CRAWLING:Crawl, STATE_CLAMBERING_RISE:ClambRise, STATE_NOCLIP:Noclip,
	STATE_CLAMBERING_LEDGE:ClambLedge, STATE_CLAMBERING_VENT:ClambVent
}

var player:Object = null
var id:int = STATE_WALKING

func _init(init_player:Object):
	player = init_player

func do(_delta:float):
	print(States[id])
	var state = States[id]
	print(state)
#	id = state.do(player, _delta)

class State:
	extends Reference
	enum {
		STATE_WALKING, STATE_LEANING, STATE_CROUCHING,
		STATE_CRAWLING, STATE_CLAMBERING_RISE, STATE_NOCLIP,
		STATE_CLAMBERING_LEDGE, STATE_CLAMBERING_VENT, 
	}
	static func do(_player:Object, _delta:float): pass

# Walking
class Walk:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_WALKING
		_player._process_frob_and_drag()
		if Input.is_action_pressed("lean"): new = STATE_LEANING
		elif Input.is_action_pressed("crouch"): new = STATE_CROUCHING
		elif Input.is_action_pressed("crawl"): new = STATE_CRAWLING
		elif Input.is_action_pressed("sneak"): _player._walk(_delta, 0.75)
		elif Input.is_action_just_pressed("noclip"): new = STATE_NOCLIP
		elif Input.is_action_pressed("zoom"):
			_player._camera.state = _player._camera.CameraState.STATE_ZOOM
		else:
			_player._camera.state = _player._camera.CameraState.STATE_NORMAL
		_player._walk(_delta)
		return new

# Crouching
class Crouch:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_CROUCHING
		if Input.is_action_pressed("zoom"):
			_player._camera.state = _player._camera.CameraState.STATE_ZOOM
		else:
			_player._camera.state = _player._camera.CameraState.STATE_NORMAL
		_player._process_frob_and_drag()
		_player._crouch()
		_player._walk(_delta, 0.65)
		return new

# Leaning
class Lean:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_LEANING
		_player._process_frob_and_drag()
		_player._lean()
		return new

# Crawling
class Crawl:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_CRAWLING
		if Input.is_action_pressed("zoom"):
			_player._camera.state = _player._camera.CameraState.STATE_ZOOM
		else:
			_player._camera.state = _player._camera.CameraState.STATE_NORMAL
		_player._crawling()
		_player.crawl_headmove(_delta)
		_player._walk(_delta, 0.45)
		return new

# Clambering Rise
class ClambRise:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_CLAMBERING_RISE
		var pos = _player.global_transform.origin
		var target = Vector3(pos.x, _player.clamber_destination.y, pos.z)
		_player.global_transform.origin = lerp(pos, target, 0.1)
		_player._crouch()
		
		var from = _player._camera.rotation_degrees.x
		var to = pos.angle_to(target)
		_player._camera.rotation_degrees.x = lerp(from, to, 0.1)
		
		var d = pos - target
		if d.length() < 0.1: new = STATE_CLAMBERING_LEDGE
		return new

# Clambering Ledge
class ClambLedge:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_CLAMBERING_LEDGE
		_player._audio_player.play_clamber_sound(false)
		var pos = _player.global_transform.origin
		_player.global_transform.origin = lerp(pos, _player.clamber_destination, 0.1)
		_player._crouch()

		var from = _player._camera.rotation_degrees.x
		var to = _player.global_transform.origin.angle_to(_player.clamber_destination)
		_player._camera.rotation_degrees.x = lerp(from, to, 0.1)

		var d = _player.global_transform.origin - _player.clamber_destination
		if d.length() < 0.1:
			_player.global_transform.origin = _player.clamber_destination
			new = STATE_CROUCHING
		return new

# Clambering Vent
class ClambVent:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_CLAMBERING_VENT
		return new

# NoClipping
class Noclip:
	extends State
	static func do(_player:Object, _delta:float):
		var new = STATE_NOCLIP
		if Input.is_action_just_pressed("noclip"): new = STATE_WALKING
		else:
			_player.collision_layer = 2
			_player.collision_mask = 2
			_player._noclip_walk()
		return new
