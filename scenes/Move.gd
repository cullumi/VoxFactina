extends PathFollow

export (float, 0.1, 10) var speed = 5

func _physics_process(delta):
	offset += speed * delta
