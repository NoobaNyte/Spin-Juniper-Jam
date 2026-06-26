extends Node

var all_spinner_ticks_sfx: Node
var all_footstep_sfx: Node

var _shop_music_playing: bool = false
var _shop_fade_tween: Tween = null

var _level_music_playing: bool = false
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

func play_shop_music():
	print("playing shop music")
	_shop_music_playing = true
	if _shop_fade_tween and _shop_fade_tween.is_valid():
		_shop_fade_tween.kill()
	var music = find_child("ShopCharivari", true, false)
	music.volume_db = 0.0
	music.play()

func fade_out_shop_music(fade_time: float = 1.0):
	_shop_music_playing = false
	var music = find_child("ShopCharivari", true, false)
	_shop_fade_tween = create_tween()
	_shop_fade_tween.tween_property(music, "volume_db", -80.0, fade_time)
	_shop_fade_tween.tween_callback(func():
		if not _shop_music_playing:
			print("shop music finished fading out")
			music.stop()
			music.volume_db = 0.0
	)

func play_level_music(fade_in_time: float = 5):
	var intro: AudioStreamPlayer
	var loop: AudioStreamPlayer

	match PlayerGlobals.selected_level:
		1:
			intro = find_child("L1Intro", true, false)
			loop = find_child("L1Loop", true, false)
		2:
			intro = find_child("L2Intro", true, false)
			loop = find_child("L2Loop", true, false)
		3:
			intro = find_child("L3Intro", true, false)
			loop = find_child("L3Loop", true, false)
		4:
			intro = find_child("L4Intro", true, false)
			loop = find_child("L4Loop", true, false)
		5:
			intro = find_child("L5Intro", true, false)
			loop = find_child("L5Loop", true, false)
		_:
			intro = find_child("L1Intro", true, false)
			loop = find_child("L1Loop", true, false)

	if not intro or not loop:
		push_error("play_level_music: could not find intro or loop for level ", PlayerGlobals.selected_level)
		return

	_level_music_playing = true
	_current_intro = intro
	_current_loop = loop

	var original_intro_db = intro.volume_db
	intro.volume_db -= 5
	intro.play()
	create_tween().tween_property(intro, "volume_db", original_intro_db, fade_in_time)

	# wait for intro to finish then hand off to loop
	await get_tree().create_timer(intro.stream.get_length()).timeout
	if not _level_music_playing:
		return

	loop.play()

	# loop infinitely until stopped
	while _level_music_playing:
		await get_tree().create_timer(loop.stream.get_length()).timeout
		if not _level_music_playing:
			break
		loop.play()

func fade_out_level_music(fade_out_time: float = 1.0):
	_level_music_playing = false

	var tween = create_tween()
	var fading: bool = false
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
