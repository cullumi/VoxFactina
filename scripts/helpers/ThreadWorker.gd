extends Object

class_name Worker

var thread:Thread
var semaphore:Semaphore
var mutex:Mutex
var local_semaphore:Semaphore
var local_mutex:Mutex

func _init(_thread, _semaphore:Semaphore=null, _mutex:Mutex=null, _local_semaphore:Semaphore=null, _local_mutex:Mutex=null):
	thread = _thread
	semaphore = _semaphore
	mutex = _mutex
	local_semaphore = _local_semaphore
	local_mutex = _local_mutex
