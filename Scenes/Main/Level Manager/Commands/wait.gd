class_name WaitCmd
extends BaseLevelCommand

@export var seconds: float = 1.0

func execute(_owner: Node) -> void:
	await _owner.get_tree().create_timer(seconds).timeout
