extends Reference

class_name Vectors

enum {X, Y, Z, OOB}

# Return an angle from one vector to another, in degrees.
static func angle_to(from, to):
	return 90 - (to.dot(from) * 90)

static func greater(a:Vector3, b:Vector3):
	return a.x > b.x or a.y > b.y or a.z > b.z

static func lesser(a:Vector3, b:Vector3):
	return a.x < b.x or a.y < b.y or a.z < b.z

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

static func clamp_to(cur:Vector3, minv:Vector3, maxv:Vector3):
	cur.x = clamp(cur.x, minv.x, maxv.x)
	cur.y = clamp(cur.y, minv.y, maxv.y)
	cur.z = clamp(cur.z, minv.z, maxv.z)
	return cur

static func string(vector:Vector3):
	return "(%.2f, %.2f, %.2f)" % [vector.x, vector.y, vector.z]
