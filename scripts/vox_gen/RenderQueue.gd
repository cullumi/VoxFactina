extends Reference

class_name RenderQueue

var queue:Array = []
var front:Chunk
var back:Chunk

func empty():
	return front == null

func erase(chunk:Chunk):
	assert(chunk.in_queue)
	if chunk.next:
		chunk.next.prev = chunk.prev
	if chunk.prev:
		chunk.prev.next = chunk.next

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

func flood(chunks:Array):
	front = chunks.pop_back()
	var cur = front
	cur.in_queue = true
	while not chunks.empty():
		cur.next = chunks.pop_back()
		cur.next.prev = cur
		cur = cur.next
		cur.in_queue = true
	back = cur

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
		chunk.in_queue = false
	return chunk
