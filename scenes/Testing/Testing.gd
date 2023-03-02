extends Node


func _ready():
	var vectors:Array = await collect_vectors(Vector3(1, 1, 1), Vector3(5, 5, 5))
	print("Finished collect vectors")
	for i in range(10):
		await get_tree().idle_frame
	count_vectors(Vector3(1, 1, 1), Vector3(5, 5, 5))
	print("Finished count vectors")
	for i in range(10):
		await get_tree().idle_frame
	loop_vectors(vectors)
	print("Finished loop vectors")
#	constant()
#	make_new()

func loop_vectors(vectors):
	var base = Vector3()
	for vector in vectors:
		var adjusted = base + vector

func collect_vectors(start, end) -> Array:
	var vectors:Array = []
	var pos = start
	while pos != end:
		pos = count_up(pos, start, end)
		vectors.append(pos)
		await get_tree().idle_frame
	return vectors

func count_vectors(start, end):
	var pos = start
	while pos != end:
		pos = count_up(pos, start, end)
#		await get_tree().idle_frame

func count_up(cur:Vector3, base:Vector3, toward:Vector3):
	cur.z += 1
	if cur.z > toward.z:
		cur.y += 1
		cur.z = base.z
		if cur.y > toward.y:
			cur.x += 1
			cur.y = base.y
	return cur

func constant():
	for _i in range(2147483647):
		var _vector = Vector3.UP

func make_new():
	for _i in range(2147483647):
		var _vector = Vector3(0, 1, 0)
