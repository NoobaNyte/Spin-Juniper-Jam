extends Node

var all_spinner_ticks_sfx: Node

func _ready() -> void:
	all_spinner_ticks_sfx = find_child("SpinnerTicks", true, false)


func play_random_wheel_tick_sfx() -> void:
	var children = all_spinner_ticks_sfx.get_children()
	if children.is_empty():
		return
	
	var sfx: AudioStreamPlayer = children[randi() % children.size()]
	sfx.pitch_scale = randf_range(0.8, 1.2)
	sfx.play()
