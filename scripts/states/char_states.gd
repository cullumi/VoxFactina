extends Node

#class_name StateMachine

var player:Object
var id:int
var state:State

func _init(init_player:Object):
	player = init_player
	start(State.NONE)

func start(_id:int):
	id = _id
	state = State.States[id].new()
	state.id = id

func do(_delta:float):
	state.do(player, _delta, self)


	
