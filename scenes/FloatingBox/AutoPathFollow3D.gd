extends PathFollow3D

@export_range(0.1, 10) var speed = 5.0

func _physics_process(delta):
	progress += speed * delta
