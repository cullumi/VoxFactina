extends Reference

class_name Chunk

var pos:Vector3 = Vector3()
var offset:Vector3 = Vector3()
var new_instance:MeshInstance = null
var instance:MeshInstance = null
var priority:int = 0
var in_render:bool = false

func _init(pos_init:Vector3=Vector3(), offset_init:Vector3=Vector3(), instance_init:MeshInstance=null):
	pos = pos_init
	offset = offset_init
	instance= instance_init
