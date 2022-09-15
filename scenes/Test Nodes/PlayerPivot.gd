extends Spatial

export (float, EXP, 0, 2) var ease_rate = 60*.1

onready var player:Player = get_node("%Player")
onready var target:Transform = transform

func _physics_process(delta):
	
	# Save the player's global position
	var player_pos = player.global_translation
	
	transform = transform.interpolate_with(target, delta * ease_rate)

	# Keep the player in their original global position.
	player.global_translation = player_pos
