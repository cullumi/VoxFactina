extends Reference

class_name RenderQueue

var queue:Array = []

func empty():
	return queue.empty()

func erase(chunk:Chunk):
	queue.erase(chunk)

func enqueue(chunk:Chunk):
	if queue.has(chunk):
		queue.erase(chunk)
	var idx = queue.bsearch_custom(chunk, self, "higher_priority", true)
	queue.insert(idx, chunk)

func flood(chunks:Array):
	queue.append_array(chunks)

func higher_priority(a:Chunk, b:Chunk):
	return a.priority > b.priority

func dequeues(num:int) -> Array:
	var chunks:Array = []
	for i in range(num):
		chunks.append(dequeue())
	return chunks

func dequeue() -> Chunk:
	return queue.pop_back()
