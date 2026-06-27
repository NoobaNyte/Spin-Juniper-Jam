extends Node

var all_spinner_ticks_sfx: Node
var all_footstep_sfx: Node

var _shop_music_playing: bool = false
var _shop_fade_tween: Tween = null
var _shop_loop_generation: int = 0

var _level_music_playing: bool = false
var _level_music_generation: int = 0
var _current_intro: AudioStreamPlayer = null
var _current_loop: AudioStreamPlayer = null


func _ready() -> void:
	all_spinner_ticks_sfx = find_child("SpinnerTicks", true, false)
	all_footstep_sfx = find_child("Footsteps", true, false)

	AudioGlobals.play_random_wheel_tick_sfx.connect(play_random_wheel_tick_sfx)
	AudioGlobals.play_poof_sfx.connect(play_poof_sfx)
	AudioGlobals.play_purchase_sfx.connect(play_purchase_sfx)
	AudioGlobals.play_random_footstep_sfx.connect(play_random_footstep_sfx)
	AudioGlobals.play_button_press_down_sfx.connect(play_button_press_down_sfx)
	AudioGlobals.play_button_press_up_sfx.connect(play_button_press_up_sfx)
	AudioGlobals.play_jump_sfx.connect(play_jump_sfx)
	AudioGlobals.play_jump_landing_sfx.connect(play_jump_landing_sfx)
	AudioGlobals.play_wall_hit_sfx.connect(play_wall_hit_sfx)
	AudioGlobals.play_lose_sfx.connect(play_lose_sfx)
	AudioGlobals.play_win_tickets_sfx.connect(play_win_tickets_sfx)
	AudioGlobals.play_win_level_sfx.connect(play_win_level_sfx)
	AudioGlobals.play_shop_music.connect(play_shop_music)
	AudioGlobals.fade_out_shop_music.connect(fade_out_shop_music)
	AudioGlobals.play_level_music.connect(play_level_music)
	AudioGlobals.fade_out_level_music.connect(fade_out_level_music)

	play_shop_music()


func play_random_wheel_tick_sfx() -> void:
	var children = all_spinner_ticks_sfx.get_children()
	if children.is_empty():
		return
	
	var sfx: AudioStreamPlayer = children[randi() % children.size()]
	sfx.play()

func play_poof_sfx():
	var sfx = find_child("Poof1", true, false)
	sfx.pitch_scale = randf_range(1.3, 1.45)
	sfx.play()

func play_purchase_sfx():
	var sfx = find_child("Purchase", true, false)
	#sfx.pitch_scale = randf_range(1.0, 1.1)
	sfx.play()

func play_random_footstep_sfx():
	var children = all_footstep_sfx.get_children()
	if children.is_empty():
		return
	
	var sfx: AudioStreamPlayer = children[randi() % children.size()]
	sfx.play()

func play_button_press_down_sfx():
	var sfx = find_child("ButtonPressDown", true, false)
	#sfx.pitch_scale = randf_range(1.0, 1.1)
	sfx.play()

func play_button_press_up_sfx():
	var sfx = find_child("ButtonPressUp", true, false)
	#sfx.pitch_scale = randf_range(1.0, 1.1)
	sfx.play()

func play_jump_sfx():
	var sfx = find_child("StartJump", true, false)
	sfx.pitch_scale = 0.9
	sfx.play()

func play_jump_landing_sfx():
	var sfx = find_child("StartJump", true, false)
	sfx.pitch_scale = randf_range(0.7, 0.8)
	sfx.play()

func play_wall_hit_sfx():
	var sfx = find_child("WallHit", true, false)
	sfx.pitch_scale = randf_range(0.9, 1.0)
	sfx.play()

func play_lose_sfx():
	var sfx = find_child("Lose", true, false)
	#sfx.pitch_scale = randf_range(0.7, 0.8)
	sfx.play()

func play_win_tickets_sfx():
	var sfx = find_child("Win2", true, false)
	#sfx.pitch_scale = randf_range(0.7, 0.8)
	sfx.play()

func play_win_level_sfx():
	var sfx = find_child("Win1", true, false)
	#sfx.pitch_scale = randf_range(0.7, 0.8)
	sfx.play()

func play_shop_music():
	print("playing shop music")
	_shop_music_playing = true
	_shop_loop_generation += 1
	var my_generation := _shop_loop_generation
	if _shop_fade_tween and _shop_fade_tween.is_valid():
		_shop_fade_tween.kill()
	var music: AudioStreamPlayer = find_child("ShopCharivari", true, false)
	music.volume_db = 0.0
	music.play()

	while _shop_music_playing and _shop_loop_generation == my_generation:
		await get_tree().create_timer(music.stream.get_length() - 0.1).timeout
		if not _shop_music_playing or _shop_loop_generation != my_generation:
			break
		music.play()

func fade_out_shop_music(fade_time: float = 1.0):
	_shop_music_playing = false
	_shop_loop_generation += 1 # kills the loop coroutine
	var music: AudioStreamPlayer = find_child("ShopCharivari", true, false)
	if _shop_fade_tween and _shop_fade_tween.is_valid():
		_shop_fade_tween.kill()
	_shop_fade_tween = create_tween()
	_shop_fade_tween.tween_property(music, "volume_db", -80.0, fade_time)
	_shop_fade_tween.tween_callback(func():
		if not _shop_music_playing:
			print("shop music finished fading out")
			music.stop()
			music.volume_db = 0.0
	)

func play_level_music(fade_in_time: float = 3):
	var intro: AudioStreamPlayer
	var loop: AudioStreamPlayer
	var intro_to_loop_offset: float
	var loop_to_loop_offset: float

	match PlayerGlobals.selected_level:
		1:
			intro = find_child("L1Intro", true, false)
			loop = find_child("L1Loop", true, false)
			intro_to_loop_offset = 0.05
			loop_to_loop_offset = 0.125
		2:
			intro = find_child("L2Intro", true, false)
			loop = find_child("L2Loop", true, false)
			intro_to_loop_offset = 0.05
			loop_to_loop_offset = 0.125
		3:
			intro = find_child("L3Intro", true, false)
			loop = find_child("L3Loop", true, false)
			intro_to_loop_offset = 0.055
			loop_to_loop_offset = 0.1166666
		4:
			intro = find_child("L4Intro", true, false)
			loop = find_child("L4Loop", true, false)
			intro_to_loop_offset = 0.05
			loop_to_loop_offset = 0.126666
		5:
			intro = find_child("L5Intro", true, false)
			loop = find_child("L5Loop", true, false)
			intro_to_loop_offset = 0.05
			loop_to_loop_offset = 0.125
		_:
			intro = find_child("L1Intro", true, false)
			loop = find_child("L1Loop", true, false)
			intro_to_loop_offset = 0.0366666
			loop_to_loop_offset = 0.1016666

	if not intro or not loop:
		push_error("play_level_music: could not find intro or loop for level ", PlayerGlobals.selected_level)
		return

	# Increment generation to kill any previous coroutine still awaiting
	_level_music_generation += 1
	var my_generation := _level_music_generation

	# Stop any currently playing level music immediately before starting new
	if _current_intro and _current_intro.playing:
		_current_intro.stop()
		_current_intro.volume_db = 0.0
	if _current_loop and _current_loop.playing:
		_current_loop.stop()
		_current_loop.volume_db = 0.0

	_level_music_playing = true
	_current_intro = intro
	_current_loop = loop

	var original_intro_db = intro.volume_db
	intro.volume_db -= 2
	intro.play()
	create_tween().tween_property(intro, "volume_db", original_intro_db, fade_in_time)

	# wait for intro to finish then hand off to loop
	await get_tree().create_timer(intro.stream.get_length() - intro_to_loop_offset).timeout
	if not _level_music_playing or _level_music_generation != my_generation:
		return

	loop.play()

	# loop infinitely until stopped
	while _level_music_playing and _level_music_generation == my_generation:
		await get_tree().create_timer(loop.stream.get_length() - loop_to_loop_offset).timeout
		if not _level_music_playing or _level_music_generation != my_generation:
			break
		loop.play()

func fade_out_level_music(fade_out_time: float = 1.0):
	_level_music_playing = false
	_level_music_generation += 1 # kills the loop coroutine immediately

	var fading: bool = false
	var tween = create_tween().set_parallel(true) # fade both simultaneously
	if _current_intro and _current_intro.playing:
		tween.tween_property(_current_intro, "volume_db", -80.0, fade_out_time)
		fading = true
	if _current_loop and _current_loop.playing:
		tween.tween_property(_current_loop, "volume_db", -80.0, fade_out_time)
		fading = true

	if fading:
		await tween.finished

	if _current_intro:
		_current_intro.stop()
		_current_intro.volume_db = 0.0
	if _current_loop:
		_current_loop.stop()
		_current_loop.volume_db = 0.0
	_current_intro = null
	_current_loop = null