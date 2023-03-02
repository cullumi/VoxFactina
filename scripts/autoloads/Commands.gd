extends Node

# Called Commands in Autoload

func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		get_tree().paused = true
		get_tree().quit()
	elif event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
