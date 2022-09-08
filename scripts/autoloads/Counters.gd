extends Node

# Named "Count" in Autoload

var counters = {}
func makes(keys:Array):
	for key in keys:
		make(key)
func make(key):
	if not counters.has(key):
		counters[key] = 0
func increment(key, amount=1):
	counters[key] += int(amount)
func decrement(key, amount=1):
	counters[key] -= int(amount)
func peek(key, do_print:bool=false) -> int:
	if do_print:
		print(key, ": ", counters[key])
	return counters[key]
func peek_all():
	for key in counters.keys():
		peek(key)
func pop(key, do_print:bool=false):
	if do_print:
		print(key, ": ", counters[key])
	var res = counters[key]
	counters[key] = 0
	return res
func pop_all(do_print:bool=false, keys:Array=counters.keys()):
	for key in keys:
		pop(key, do_print)
