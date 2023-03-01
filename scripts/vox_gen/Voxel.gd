extends RefCounted

class_name Voxel

var pos # The Voxel's Position Relative to it's Chunk
var offset # The Voxel's World3D Position
var color # The Voxel's Color

func _init(b_pos,v_off,v_color):
	pos = b_pos
	offset = v_off
	color = v_color
