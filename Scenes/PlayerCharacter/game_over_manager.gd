extends Node

func _ready() -> void:
	PlayerGlobals.game_over.connect(game_over)


func game_over():
	PlayerGlobals.game_ended = true
	WheelGlobals.speed_transition(0, 1)
	stop_music_after_wait()
	if PlayerGlobals.won_level:
		print("you won!")
	else:
		print("you lost!")
		PlayerGlobals.lost_level = true
		PlayerGlobals.disable_movement = true
		# if player didn't die to a wall, disappear them
		if not PlayerGlobals.fell:
			PlayerGlobals.disappear_player.emit()
			
	
	PlayerGlobals.won_level = false

	# wait for the hit anim to be done
	await get_tree().create_timer(0.5).timeout
	if PlayerGlobals.lost_level:
		AudioGlobals.play_lose_sfx.emit()
		# wait for sfx to be done
		await get_tree().create_timer(1.95).timeout

	# if player died to a wall, disappear them
	if PlayerGlobals.lost_level and PlayerGlobals.fell:
		PlayerGlobals.disappear_player.emit()


	await get_tree().create_timer(0.5).timeout
	# do ticket stuff
	PlayerGlobals.reset_game.emit()

func stop_music_after_wait():
	await get_tree().create_timer(0.1).timeout
	AudioGlobals.fade_out_level_music.emit(0.2)
