class_name TransitionWheelSpeedCmd
extends BaseLevelCommand

@export var target_speed: float = 50.0
@export var duration: float = 30.0

func check_time():
	total_command_time = duration

func execute(_owner: Node) -> void:
	await WheelGlobals.speed_transition(target_speed, duration)
