extends Spatial

### Properties

## Nodes
onready var pivot:PlayerPivot = get_node("%PlayerPivot")
onready var planets:Array = get_tree().get_nodes_in_group("Planet")
var cur_planet:Planet

### Triggers

func _ready():
	for planet in planets:
		planet.pivot = pivot
		planet.orbiting = false
		planet.connect("player_entered", self, "_on_Planet_player_entered")
		planet.connect("player_exited", self, "_on_Planet_player_exited")
		planet.generate()

func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		get_tree().paused = true
		get_tree().quit()

func _exit_tree():
	Count.pop_all()

### Region Transfers

func _on_Planet_player_entered(planet:Planet):
	assert(cur_planet != planet) # Should never reenter same planet
	if cur_planet:
		cur_planet.orbiting = false
	cur_planet = planet
	cur_planet.orbiting = true
	pivot.orbit = cur_planet

func _on_Planet_player_exited(planet:Planet):
	assert(cur_planet == planet) # Should not exit when not current
	if cur_planet == planet:
		cur_planet.orbiting = false
		cur_planet = null
		pivot.orbit = null
