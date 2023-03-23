extends Node

var count:int = (OS.get_processor_count() * 2)
var threads:Array = []
var workers:Dictionary = {}

enum {WORK, DONE, IDLE, EXIT}
var states:Dictionary = {}
var jobs:Dictionary = {}

signal idling
var idles:Array = []
var done:int = 0

var mutex:Mutex = Mutex.new()
var semaphore:Semaphore = Semaphore.new()
var mutexes:Dictionary = {}
var semaphores:Dictionary = {}

func get_state(id):
	var state
	mutexes[id].lock()
	state = states[id]
	mutexes[id].unlock()
	return state

func set_state(id, val):
	mutexes[id].lock()
	states[id] = val
	mutexes[id].unlock()
	semaphores[id].post()

### Worker Management

func _enter_tree():
	print("Initializing ThreadPool: %d workers" % count)
	for _i in range(count):
		var thread = Thread.new()
		threads.append(thread)
		thread.start(work.bind({"thread":thread}))
		var id = thread.get_id()
		assert(id != "")
		mutexes[id] = Mutex.new()
		semaphores[id] = Semaphore.new()
		workers[id] = Worker.new(thread, semaphore, mutex, semaphores[id], mutexes[id])
		idle_worker(id)

func idle_worker(id):
	set_state(id, IDLE)
	jobs[id] = null
	idles.push_back(id)

func report_done():
	mutex.lock()
	done += 1
	mutex.unlock()
#	semaphore.post()

func num_done():
	mutex.lock()
	var num:int = done
	mutex.unlock()
	return num

func _process(_delta):
	var num = num_done()
	if num:
		finish_jobs(num)

func finish_jobs(num:int):
	var finished:int = 0
	for id in states:
		if get_state(id) == DONE:
			var job = jobs[id]
			if job.callback.is_valid() and job.has("results"):
				job.callback.callv([job.results])
			idle_worker(id)
			finished += 1
			if finished == num:
				break
	mutex.lock()
	done -= finished
	mutex.unlock()
	emit_signal("idling")

func _exit_tree():
	for worker_state in states:
		set_state(worker_state, EXIT)
	while not threads.is_empty():
		for thread in threads:
			if not thread.is_alive():
				thread.wait_to_finish()
		await get_tree().process_frame
	for worker in workers:
		worker.free()

### Job Management

func start_job(callable:Callable, args=[], callback:Callable=Callable()) -> Worker:
	var id = idles.pop_back()
	if id:
		jobs[id] = {
			"callable":callable,
			"args":args,
			"callback":callback
		}
		set_state(id, WORK)
		assert(workers[id])
		return workers[id]
	else:
		return null

### Worker

func work(args={"thread":null}):
	if args.thread:
		var exit:bool = false
		var id:String = args.thread.get_id()
		while not exit:
			semaphores[id].wait()
			match get_state(id):
				WORK:
					var job = jobs[id]
					var result = await job.callable.callv(job.args)
					jobs[id]["results"] = result
					set_state(id, DONE)
					report_done()
				EXIT:
					exit = true
				_:
					pass
