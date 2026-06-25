class_name SetGapChanceCmd
extends BaseLevelCommand

@export var new_gap_chance: int = 0

func execute(_owner: Node) -> void:
	WheelGlobals.empty_piece_chance = new_gap_chance
