extends Node

func _ready() -> void:
	PlayerGlobals.game_over.connect(game_over)


func game_over():
	WheelGlobals.speed_transition(0, 1)
	stop_music_after_wait()
	if PlayerGlobals.won_level:
		print("you won!")
	else:
		PlayerGlobals.lost_level = true
		print("you lost.")
		PlayerGlobals.disable_movement = true
		PlayerGlobals.disappear_player.emit()
	
	PlayerGlobals.won_level = false

	# open retry / go to shop / win screen UI
	## CRITICAL - THE GAME OVER SCREEN BUTTONS SHOULD TRIGGER THIS, THE RESET GAME EMIT HERE IS TEMPORARY
	await get_tree().create_timer(1.0).timeout
	PlayerGlobals.reset_game.emit()

func stop_music_after_wait():
	await get_tree().create_timer(0.1).timeout
	AudioGlobals.fade_out_level_music.emit(0.2)
