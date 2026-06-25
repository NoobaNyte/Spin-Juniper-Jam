extends Area3D

@export var default_spawn_parent: Node # the parent that spawned objects become a child of. assign in inspector, or falls back to self

func _ready() -> void:
	WheelGlobals.spawn_falling_objects.connect(spawn_falling_objects)


func spawn_falling_objects(quantity: int, time_in_seconds: float, objects: Variant) -> void:
	# Normalize input: accept a single PackedScene or an Array of them
	var scene_list: Array[PackedScene] = []
	if objects is PackedScene:
		scene_list = [objects]
	elif objects is Array:
		for item in objects:
			if item is PackedScene:
				scene_list.append(item)

	if scene_list.is_empty():
		push_error("spawn_falling_objects: no valid PackedScenes provided")
		return

	var interval := time_in_seconds / float(quantity)

	for i in quantity:
		await get_tree().create_timer(interval).timeout
		var scene = scene_list[randi() % scene_list.size()]
		var instance = scene.instantiate()
		var parent = default_spawn_parent if default_spawn_parent else self
		parent.add_child(instance)
		instance.global_position = _get_random_position_in_trimesh()


func _get_random_position_in_trimesh() -> Vector3:
	# Get the AABB of the trimesh shape to sample a random point within its bounds
	var collision_shape: CollisionShape3D
	for child in get_children():
		if child is CollisionShape3D:
			collision_shape = child
			break

	if not collision_shape or not collision_shape.shape is ConcavePolygonShape3D:
		push_error("spawn_falling_objects: Area3D must have a ConcavePolygonShape3D (trimesh)")
		return global_position

	var aabb: AABB = collision_shape.shape.get_debug_mesh().get_aabb()
	var gt: Transform3D = collision_shape.global_transform

	# Sample random point within the AABB, then transform to world space
	var local_pos := Vector3(
		randf_range(aabb.position.x, aabb.position.x + aabb.size.x),
		aabb.position.y + aabb.size.y, # spawn at the TOP of the bounds
		randf_range(aabb.position.z, aabb.position.z + aabb.size.z)
	)

	return gt * local_pos
