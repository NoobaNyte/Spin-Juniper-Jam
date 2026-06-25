class_name SetPieceAngleSizesCmd
extends BaseLevelCommand

@export var new_min_angle_size: int = 50
@export var new_max_angle_size: int = 60

func execute(_owner: Node) -> void:
	WheelGlobals.min_piece_angle_size = new_min_angle_size
	WheelGlobals.max_piece_angle_size = new_max_angle_size
