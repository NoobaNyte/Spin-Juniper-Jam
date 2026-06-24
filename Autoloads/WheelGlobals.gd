extends Node

@warning_ignore("unused_signal")
signal spawn_new_wheel_piece # emmitted in piece_gen_template.gd and used to tell generate_piece.gd to spawn a new wheel piece (when the piece has rotated enough to the spawn point area/pos)

## general
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
