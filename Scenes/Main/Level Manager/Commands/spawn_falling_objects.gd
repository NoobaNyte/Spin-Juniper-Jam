class_name SpawnFallingObjectsCmd
extends BaseLevelCommand

@export var quantity: int = 10
@export var spawn_objects_over_this_many_seconds: float = 5.0
@export var objects: Array[PackedScene]

func execute(_owner: Node) -> void:
	WheelGlobals.spawn_falling_objects.emit(quantity, spawn_objects_over_this_many_seconds, objects)
