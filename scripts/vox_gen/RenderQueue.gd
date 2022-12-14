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
	print("Enqueue (", front," <- ", chunk, ")")
	if chunk.in_queue: erase(chunk)
	# Put chunk at front of queue
	chunk.next = front
	chunk.prev = null
	if front:
		front.prev = chunk
	front = chunk
	# Mark as in queue
	chunk.in_queue = true
#	var idx = queue.bsearch_custom(chunk, self, "higher_priority", true)
#	queue.insert(idx, chunk)

func flood(chunks:Array):
#	queue.append_array(chunks)
#	chunks = chunks.duplicate()
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
		print("Chunk exists")
		front = chunk.next
		front.prev = null
		# Mark as in queue
		chunk.in_queue = false
	else:
		print("No front")
	return chunk
#	var chunk = queue.pop_back()
