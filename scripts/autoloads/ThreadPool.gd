extends Node

const count:int = 16
var workers:Array = []

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
	for _i in range(count):
		var thread = Thread.new()
		workers.append(thread)
		thread.start(self, "worker", {"thread":thread})
		var id = thread.get_id()
		mutexes[id] = Mutex.new()
		semaphores[id] = Semaphore.new()
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
			if job.cb_object and job.cb_method and job.has("results"):
				job.cb_object.callv(job.cb_method, [job.results])
			idle_worker(id)
			finished += 1
			if finished == num:
				break
	mutex.lock()
	done -= finished
	mutex.unlock()
	emit_signal("idling")

func _exit_tree():
	for worker in states:
		set_state(worker, EXIT)
	while not workers.empty():
		for thread in workers:
			if not thread.is_alive():
				thread.wait_to_finish()
		yield(get_tree(), "idle_frame")

### Job Management

func start_job(object:Object, method:String, args=[], cb_object:Object=null, cb_method:String=""):
	var id = idles.pop_back()
	if id:
		jobs[id] = {
			"object":object,
			"method":method,
			"args":args,
			"cb_object":cb_object,
			"cb_method":cb_method,
		}
		set_state(id, WORK)
		return true
	else:
		return false

### Worker

func worker(args={"thread":null}):
	if args.thread:
		var exit:bool = false
		var id:String = args.thread.get_id()
		while not exit:
			semaphores[id].wait()
			match get_state(id):
				WORK:
					var job = jobs[id]
					var work = job.object.callv(job.method, job.args)
					if work is GDScriptFunctionState:
						yield(work, "completed")
					jobs[id]["results"] = work
					set_state(id, DONE)
					report_done()
				EXIT:
					exit = true
				_:
					pass
