extends Node

@warning_ignore("unused_signal")
signal spawn_new_wheel_piece # emmitted in piece_gen_template.gd and used to tell generate_piece.gd to spawn a new wheel piece (when the piece has rotated enough to the spawn point area/pos)

## general
var preview_rotation_speed: float = 55
var rotation_speed: float = 55
var min_piece_angle_size: int = 30
var max_piece_angle_size: int = 60

## colors
var level_1_colors: Array[Color]
var level_2_colors: Array[Color]
var level_3_colors: Array[Color]
var level_4_colors: Array[Color]
var level_5_colors: Array[Color]

var do_checkered_colors: bool = true
var color_index: int = 0

## walls
var level_1_walls: Array[PackedScene]
var level_2_walls: Array[PackedScene]
var level_3_walls: Array[PackedScene]
var level_4_walls: Array[PackedScene]
var level_5_walls: Array[PackedScene]

var gen_walls_in_order: bool = true
var wall_index: int = 0

var start_of_level_wheel_speed: float = 20 # assigned and used in level_manager.gd while the wheel is being reset/prepped when you start a level, wheel speed gets reset to this speed

## util functions
var speed_tween: Tween

func speed_transition(new_speed: float, transition_time: float = 1) -> void:
	if speed_tween and speed_tween.is_valid():
		speed_tween.kill()

	speed_tween = create_tween()

	# ease in to target speed
	speed_tween.tween_method(
		func(val: float): WheelGlobals.rotation_speed = val,
		WheelGlobals.rotation_speed,
		new_speed,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
