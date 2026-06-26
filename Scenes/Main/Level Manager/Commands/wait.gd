class_name WaitCmd
extends BaseLevelCommand

@export var seconds: float = 1.0

func check_time():
	total_command_time = seconds

func execute(_owner: Node) -> void:
	await _owner.get_tree().create_timer(seconds).timeout
