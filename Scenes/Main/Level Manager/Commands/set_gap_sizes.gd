class_name SetGapSizesCmd
extends BaseLevelCommand

@export var new_min_gap_angle_size: int = 10
@export var new_max_gap_angle_size: int = 20

func execute(_owner: Node) -> void:
	WheelGlobals.min_gap_angle_size = new_min_gap_angle_size
	WheelGlobals.max_gap_angle_size = new_max_gap_angle_size
