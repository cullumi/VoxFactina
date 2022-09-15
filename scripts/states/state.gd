
extends Node

#class_name States

# State Constants
enum State {NONE, IDLE}
enum {NONE, IDLE}
var States = {
	NONE:None, IDLE:Idle
}

# State Properties
export (State) var id setget set_id

func set_id(id):
	id = id
	if id != NONE:
		get_parent().add_child(States[id].new())
		queue_free()

# State Functions
func do(_player:Object, _delta:float, _sm=null): pass

### State Definitions

# None
class None:
	extends Reference
	func do(_player:Object, _delta:float, _sm=null):
		print("State: None")

# Walking
class Idle:
	extends Reference
	func do(_player:Object, _delta:float, _sm=null):
		print("State: Idle")
