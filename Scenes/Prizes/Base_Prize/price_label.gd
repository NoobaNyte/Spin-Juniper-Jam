extends Sprite3D

@onready var price_text = $SubViewport/PriceText

func _ready() -> void:
	fade_out(self, 0)
	

func update_price():
	# new_price is emitted from each prize in the base_prize.gd "price" var that they all have
	var new_price = owner.price
	price_text.text = "$" + str(new_price)

func fade_in(target: Node3D, duration: float = 0.5) -> Signal:
	print("trying to fade in")
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


func fade_out(target: Node3D, duration: float = 0.5) -> Signal:
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
			#target.hide()
			pass
)
   
	# 4. Return the tween directly at the end of the function!
	return tween.finished

func wait(time: float) -> Signal:
	var wait_tween = create_tween()
	wait_tween.tween_interval(time)

	return wait_tween.finished
