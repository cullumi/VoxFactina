extends Reference

class_name RenderQueue

var queue:Array = []
var front:Chunk
var back:Chunk

func empty():
	return front == null

func erase(chunk:Chunk):
	if chunk.in_queue:
		if chunk.next:
			chunk.next.prev = chunk.prev
		if chunk.prev:
			chunk.prev.next = chunk.next

func count(chunk:Chunk=front):
	var num:int = 0
	var verified:Dictionary
	while chunk != null:
		num += 1
		assert(not verified.get(chunk), "duplicate chunk in queue")
		verified[chunk] = true
		chunk = chunk.next
	return num

func enqueue(chunk:Chunk):
	if chunk.in_queue: erase(chunk)
	# Put chunk at front of queue
	chunk.next = front
	chunk.prev = null
	if front:
		front.prev = chunk
	front = chunk
	# Mark as in queue
	chunk.in_queue = true

func flood(chunks:Array, overwrite:bool=false):
	if not chunks.empty():
		print("Flooding with ", chunks.size(), " chunks.")
		var cur
		if overwrite or front == null:
			var next:Chunk
			while next == null or next.in_queue:
				next = chunks.pop_back()
			front = next
			front.in_queue = true
			cur = front
		else:
			cur = back
		while not chunks.empty():
			var next:Chunk = chunks.pop_back()
			if not next.in_queue:
				assert(cur.next == null, "cur != null")
				cur.next = next
				cur.next.prev = cur
				cur = cur.next
				cur.in_queue = true
			
		back = cur
		print("Render Queue size of ", count(), ".")

func higher_priority(a:Chunk, b:Chunk):
	return a.priority < b.priority

func dequeues(num:int) -> Array:
	var chunks:Array = []
	for _i in range(num):
		chunks.append(dequeue())
	return chunks

func dequeue() -> Chunk:
	# Pop chunk off queue
	var chunk = front
	if chunk:
		if chunk.next:
			chunk.next.prev = null
		front = chunk.next
		# Mark as in queue
		chunk.prev = null
		chunk.next = null
		chunk.in_queue = false
	return chunk
