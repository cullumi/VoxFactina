extends Node

# Named "Count" in Autoload

var counters = {}

func makes(keys:Array, count:Dictionary=counters):
	for key in keys:
		make(key)
func make(key, count:Dictionary=counters):
	count[key] = count.get(key, 0)

func push(key, amount=1, count:Dictionary=counters):
	count[key] = count.get(key, 0) + amount

func increment(key, amount=1, count:Dictionary=counters):
	count[key] += int(amount)
func decrement(key, amount=1, count:Dictionary=counters):
	count[key] -= int(amount)
	
func peek(key, do_print:bool=false, count:Dictionary=counters) -> int:
	if do_print:
		print(key, ": ", count[key])
	return count[key]
func peek_all(do_print:bool=false, keys=null, count:Dictionary=counters):
	if keys == null: keys = count.keys()
	for key in keys:
		peek(key, do_print, count)

func pop(key, do_print:bool=false, count:Dictionary=counters):
	if do_print:
		print(key, ": ", count[key])
	var res = count[key]
	count[key] = 0
	return res
func pop_all(do_print:bool=false, keys=null, count:Dictionary=counters):
	if keys == null: keys = count.keys()
	for key in keys:
		pop(key, do_print, count)
