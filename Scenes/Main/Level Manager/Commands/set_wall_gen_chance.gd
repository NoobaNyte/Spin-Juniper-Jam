class_name SetWallGenChanceCmd
extends BaseLevelCommand

@export var new_wall_gen_chance: int = 0

func execute(_owner: Node) -> void:
	WheelGlobals.wall_gen_chance = new_wall_gen_chance
