class_name SpawnFallingObjectsCmd
extends BaseLevelCommand

@export var quantity: int = 10
@export var spawn_objects_over_this_many_seconds: float = 5.0 # does not wait this many seconds before executing next command
@export var objects: Array[PackedScene]
@export var min_spawn_velocity: float = 0
@export var max_spawn_velocity: float = 0

func execute(_owner: Node) -> void:
	WheelGlobals.spawn_falling_objects.emit(quantity, spawn_objects_over_this_many_seconds, objects, min_spawn_velocity, max_spawn_velocity)
