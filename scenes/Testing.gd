extends Node


func _ready():
	count_vectors(Vector3(.25,.25,.25), Vector3(3.25,3.25,3.25))
#	constant()
#	make_new()

func count_up(cur:Vector3, base:Vector3, toward:Vector3):
	cur.z += 1
	if cur.z > toward.z:
		cur.y += 1
		cur.z = base.z
		if cur.y > toward.y:
			cur.x += 1
			cur.y = base.y
	return cur

func count_vectors(start, end):
	var pos = start
	while pos != end:
		print(pos)
		pos = count_up(pos, start, end)
		yield(get_tree(), "idle_frame")

func constant():
	for _i in range(2147483647):
		var _vector = Vector3.UP

func make_new():
	for _i in range(2147483647):
		var _vector = Vector3(0, 1, 0)
