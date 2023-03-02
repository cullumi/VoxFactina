extends RefCounted

class_name Vectors

enum {X, Y, Z, OOB}

static func to_meta_name(vector:Vector3) -> String:
	var absv = vector.abs()
	var prefix = "vox_pos_" if absv == vector else "neg_pos_"
	var conv = func (val:float): return "_" + str(val)
	var content = conv.call(absv.x) + conv.call(absv.y) + conv.call(absv.z)
	return prefix + content

# Return an angle from one vector to another, in degrees.
static func angle_to(from, to):
	return 90 - (to.dot(from) * 90)

static func any_greater(a:Vector3, b:Vector3):
	return a.x > b.x or a.y > b.y or a.z > b.z

static func any_lesser(a:Vector3, b:Vector3):
	return a.x < b.x or a.y < b.y or a.z < b.z

static func greater(a:Vector3, b:Vector3):
	if a.x > b.x: return true
	if a.y > b.y: return true
	if a.z > b.z: return true

static func lesser(a:Vector3, b:Vector3):
	if a.x < b.x: return true
	if a.y < b.y: return true
	if a.z < b.z: return true

static func all(to:Vector3, from:Vector3=Vector3(), order:Array=[X,Y,Z]):
	var combos = []
	var a = abs(order[0])
	var b = abs(order[1])
	var c = abs(order[2])
	var ord_vec = Vector3()
	ord_vec[a] = order[0]
	ord_vec[b] = order[1]
	ord_vec[c] = order[2]
	var signs = (to-from).sign() * ord_vec.sign()
	for aa in range(from[a], to[a]+signs[a], signs[a]):
		for bb in range(from[b], to[b]+signs[b], signs[b]):
			for cc in range(from[c], to[c]+signs[c], signs[c]):
				var vector = Vector3()
				vector[a] = aa
				vector[b] = bb
				vector[c] = cc
				combos.append(vector)
	return combos

static func count_to(cur:Vector3, toward:Vector3, base:Vector3=Vector3()):
	cur.z += 1
	if cur.z > toward.z:
		cur.y += 1
		cur.z = base.z
		if cur.y > toward.y:
			cur.x += 1
			cur.y = base.y
	return cur

static func collect_vectors(start, end) -> Array:
	var vectors:Array = []
	var cur = start
	while cur != end:
		vectors.append(cur)
		cur = count_to(cur, end, start)
	vectors.append(cur)
	return vectors

static func clamp_to(cur:Vector3, minv:Vector3, maxv:Vector3):
	cur.x = clamp(cur.x, minv.x, maxv.x)
	cur.y = clamp(cur.y, minv.y, maxv.y)
	cur.z = clamp(cur.z, minv.z, maxv.z)
	return cur

static func string(vector:Vector3):
	return "(%.2f, %.2f, %.2f)" % [vector.x, vector.y, vector.z]

# 3 coord matrix display

const pairs = [
		{"a":X, "b":Y},
		{"a":Z, "b":Y},
		{"a":X, "b":Z},
	]
static func show_3coords(vectors:Array, dims:Vector3):
	print("3 Coords")
	
	# Top Header
	var top = ""
	for pair in pairs:
		top += header_2coord(vectors, pair.a, dims)
	print(top)
	
	# Top Line
	var top_line = ""
	for pair in pairs:
		top_line += line_2coord(vectors, pair.a, dims)
	print(top_line)
	
	# Rows
	for bb in range(dims[Y]):
		var line = ""
		for pair in pairs:
			line += row_2coord(vectors, pair.a, pair.b, bb, dims)
		print(line)

# vector search
static func has_vector(vectors:Array, av:float, bv:float, a:int, b:int):
	for vector in vectors:
		if vector[a] == av and vector[b] == bv:
			return true
	return false

# 2 coord line functions
static func row_2coord(vectors:Array, a:int, b:int, bb:int, dims:Vector3):
	var digit_max = ceil(dims[a]/10)
	var line_digit = max(0, digit_max - ceil(bb+1/10.0))
	var line = "   " + " ".repeat(line_digit) + str(bb) + " |"
	for aa in range(dims[a]):
		var digit = max(0, digit_max - ceil(aa+1/10.0))
		line += " " + " ".repeat(digit)
		if has_vector(vectors, aa, bb, a, b):
			line += "*"
		else:
			line += " "
	line += " "
	return line

static func header_2coord(_vectors:Array, a:int, dims:Vector3):
	var space = " ".repeat(int(floor(dims[a]/10)))
	var top = space + "     |"
	for aa in range(dims[a]):
		top += " " + str(aa)
	top += " "
	return top

static func line_2coord(_vectors:Array, a:int, dims:Vector3):
	var digits:int = int(ceil(dims[a]/10))
	var left = "-".repeat(digits)
	var right = "--".repeat(int(dims[a]))
	for digit in range(1, digits):
		var count:int = int(dims[a]) % int(pow(10, digit))
		right += "-".repeat(digit).repeat(count)
	var line = "  -" + left + "-+" + right + "-"
	return line
