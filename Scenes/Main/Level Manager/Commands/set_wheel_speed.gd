class_name SetWheelSpeedCmd
extends BaseLevelCommand

@export var speed: float = 20.0

func execute(_owner: Node) -> void:
	WheelGlobals.rotation_speed = speed
