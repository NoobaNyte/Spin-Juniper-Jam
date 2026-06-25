extends Node

var speed_tween: Tween

func _ready() -> void:
	PlayerGlobals.game_over.connect(game_over)


func game_over():
	print("game over!")
	stop_wheel()
	
	if PlayerGlobals.won_level:
		pass
	else:
		PlayerGlobals.disable_movement = true
		PlayerGlobals.disappear_player.emit()
	
	PlayerGlobals.won_level = false
	PlayerGlobals.reset_game.emit()


func stop_wheel() -> void:
	if speed_tween and speed_tween.is_valid():
		speed_tween.kill()

	speed_tween = create_tween()

	# ease in to target speed
	speed_tween.tween_method(
		func(val: float): WheelGlobals.rotation_speed = val,
		WheelGlobals.rotation_speed,
		0,
		1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)