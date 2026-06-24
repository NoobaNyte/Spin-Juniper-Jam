extends Node

@warning_ignore("unused_signal")
signal spawn_new_wheel_piece # emmitted in piece_gen_template.gd and used to tell generate_piece.gd to spawn a new wheel piece (when the piece has rotated enough to the spawn point area/pos)


var rotation_speed: float = 55