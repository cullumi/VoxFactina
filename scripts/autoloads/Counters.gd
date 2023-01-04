extends Node

# Named "Count" in Autoload

var counters = {}

func makes(keys:Array, count:Dictionary=counters):
	for key in keys:
		make(key, count)
func make(key, count:Dictionary=counters):
	count[key] = count.get(key, 0)

func push(key, amount:int=1, count:Dictionary=counters):
	count[key] = count.get(key, 0) + amount

func increment(key, amount:int=1, count:Dictionary=counters):
	count[key] += int(amount)
func decrement(key, amount:int=1, count:Dictionary=counters):
	count[key] -= int(amount)
	
func peek(key, do_print:bool=false, count:Dictionary=counters) -> int:
	if do_print:
		print(key, ": ", count[key])
	return count[key]
func peek_all(do_print:bool=false, keys=null, count:Dictionary=counters):
	if keys == null: keys = count.keys()
	var res:Array = []
	for key in keys:
		res.append(peek(key, do_print, count))
	return res

func pop(key, do_print:bool=false, count:Dictionary=counters):
	if do_print:
		print(key, ": ", count[key])
	var res = count[key]
	count[key] = 0
	return res
	
func pop_all(erase:bool=false, do_print:bool=false, keys=null, count:Dictionary=counters):
	if keys == null: keys = count.keys()
	var res:Array = []
	for key in keys:
		res.append(pop(key, do_print, count))
	if erase: count.clear()
	return res
