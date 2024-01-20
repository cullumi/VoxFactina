extends Node3D

### Properties

## Nodes
@export var pivot:PlayerPivot #get_node("%PlayerPivot")
@onready var planets:Array = get_tree().get_nodes_in_group("Planet")
var cur_planet:Planet

### Triggers

func _ready():
	var chunk:Chunk = Chunk.new(null)
	print(chunk.get_meta_list())
	
	for planet in planets:
		planet.pivot = pivot
		planet.orbiting = false
		planet.connect("player_entered",Callable(self,"_on_Planet_player_entered"))
		planet.connect("player_exited",Callable(self,"_on_Planet_player_exited"))
		planet.generate()

func _exit_tree():
	print("Exiting tree")
	Count.pop_all(true,true)

### Region Transfers

func _on_Planet_player_entered(planet:Planet):
	assert(cur_planet != planet) # Should never reenter same planet
	if cur_planet:
		cur_planet.orbiting = false
	cur_planet = planet
	cur_planet.orbiting = true
	if (pivot):
		pivot.orbit = cur_planet

func _on_Planet_player_exited(planet:Planet):
	assert(cur_planet == planet) # Should not exit when not current
	if cur_planet == planet:
		cur_planet.orbiting = false
		cur_planet = null
		pivot.orbit = null
