extends Spatial

### Properties

## Nodes
onready var pivot:PlayerPivot = get_node("%PlayerPivot")
onready var planets:Array = get_tree().get_nodes_in_group("Planet")


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


### Region Transfers

var moving:bool = false # Used to ignore enter/exit signals while reparenting.

func _on_Planet_player_entered(planet:Planet):
	if not moving:
		prints("Entered", planet)
		var parent = pivot.get_parent()
		assert(parent)
		if parent != planet:
			moving = true
			var player_pos = pivot.player.global_translation
			parent.remove_child(pivot)
			planet.add_child(pivot)
			pivot.translation = Vector3()
			pivot.player.global_translation = player_pos
			moving = false


func _on_Planet_player_exited(planet:Planet):
	if not moving:
		prints("Exited:", planet)
		if pivot.get_parent() == planet:
			moving = true
			var player_pos = pivot.player.global_translation
			planet.remove_child(pivot)
			planet.get_parent().add_child(pivot)
			pivot.translation = Vector3()
			pivot.player.global_translation = player_pos
			moving = false
