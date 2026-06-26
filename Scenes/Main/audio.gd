extends Node

var all_spinner_ticks_sfx: Node
var all_footstep_sfx: Node

func _ready() -> void:
	all_spinner_ticks_sfx = find_child("SpinnerTicks", true, false)
	all_footstep_sfx = find_child("Footsteps", true, false)


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
