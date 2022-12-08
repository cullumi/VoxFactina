extends Spatial

class_name PlayerPivot

export (float, EXP, 0, 2) var ease_rate = 60*.1

onready var player:Player = get_node("%Player")
onready var target:Transform = transform
onready var altitude:float = -1
var orbit:Spatial

### Triggers

func _physics_process(delta):
	# Save the player's global position.
	var player_pos = player.global_translation
	
	# Interpolate the pivot toward's it's target orientation.
	transform = transform.interpolate_with(target, delta * ease_rate)
	
	# Keep Pivot and Player at same global position w/ orbit adjustment
	var final_pos = player_pos
	if orbit:
		var shift:Vector3 = player.translation
		if shift:
			var orbit_diff:Vector3 = player_pos - orbit.global_translation
			if altitude < 0: altitude = orbit_diff.length()
			altitude += shift.y
			var orbit_dir:Vector3 = orbit_diff.normalized()
			var orbit_mag:float = altitude
			var orbit_pos = orbit.global_translation + (orbit_dir * orbit_mag)
			final_pos = orbit_pos
	player.translation = Vector3()
	global_translation = final_pos
	orthonormalize()

### Player Orientation

# Get the gravity based on the player's location; reorient the player if needed.
var cur_gravity = Vector3()
func reorient_player(gravity):
	if (gravity - cur_gravity).length() >= 0.001:
		orient_player(gravity, cur_gravity)
		cur_gravity = gravity

# Orient the Player based on a given gravity vector
func orient_player(gravity, last_gravity):
	var angle:float = -gravity.angle_to(last_gravity)
	var axis:Vector3 = gravity.cross(last_gravity).normalized()
	if axis and axis.is_normalized():
		if angle != 0 and angle != -0:
			# Roll the basis
			var basis = target.basis.rotated(axis, angle)
			target.basis = basis.orthonormalized()
	else:
		prints("Axis not normalized...", axis, "[%.2f]" % angle)


### Basis Debugging

# Used to see if the player has the same global "up" as it's pivot point.
var last_cross = null
func cross_debug():
	var new_cross = player.global_transform.basis.y.cross(transform.basis.y)
	if new_cross != last_cross:
		last_cross = new_cross
		prints("Y Cross:", last_cross)

# Prints out the whole basis matrix.
func bprint(basis:Basis):
	prints("\tbasis:\t| %f, %f, %f |" % [basis.x.x, basis.y.x, basis.z.x])
	prints("\t      \t| %f, %f, %f |" % [basis.x.y, basis.y.y, basis.z.y])
	prints("\t      \t| %f, %f, %f |" % [basis.x.z, basis.y.z, basis.z.z])

# Prints out the components for gravity-based orientation.
func bdebug(basis:Basis, vecs:Dictionary, gravity:Vector3):
	prints("\tgrav:", gravity)
	prints("\tx:", vecs.x)
	prints("\ty:", vecs.y)
	prints("\tz:", vecs.z)
	prints("\tx:", basis.x, "y:", basis.y, "z:", basis.z)
	bprint(basis)
