extends Control
class_name BaseUIElement

var faded_out: bool = false # for selectedanomalylabel


func fade_in(target: CanvasItem, duration: float = 0.5) -> Signal:
	faded_out = false
	# 1. Force the target to start completely invisible
	target.modulate.a = 0.0
	target.show()
   
	# 2. Create the smooth ease-in/out tween
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
   
	# 3. Animate alpha to 1.0
	tween.tween_property(target, "modulate:a", 1.0, duration)
   
	# 4. Return the tween directly at the end of the function!
	return tween.finished


func fade_out(target: CanvasItem, duration: float = 0.5) -> Signal:
	faded_out = true
	# 1. Create the smooth ease-in/out tween
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
   
	# 2. Animate alpha to 0.0
	tween.tween_property(target, "modulate:a", 0.0, duration)
   
	# 3. Keep your hide logic, but remove the return from inside it
	tween.finished.connect(func():
		# Safety check just in case the node was deleted before the tween finished
		if is_instance_valid(target):
			target.hide()
)
   
	# 4. Return the tween directly at the end of the function!
	return tween.finished

func wait(time: float) -> Signal:
	var wait_tween = create_tween()
	wait_tween.tween_interval(time)

	return wait_tween.finished
