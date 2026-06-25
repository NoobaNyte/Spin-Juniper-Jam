extends RigidBody3D

var original_transform: Transform3D
var height: float = 1.0

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout # wait for string to go into position first
	original_transform = global_transform

func set_height() -> void:
	var mesh_instance = $MeshInstance3D
	var collision_shape = $CollisionShape3D

	# 1. Update the actual height of the Mesh and Shape resources
	mesh_instance.mesh.height = height
	collision_shape.shape.height = height
	
	# 2. Calculate the offset needed to keep the bottom at 0
	# Since cylinders generate from the center, we move them up by half their height.
	var y_offset = height / 2.0
	
	# 3. Apply the offset to their local positions
	mesh_instance.position.y = y_offset
	collision_shape.position.y = y_offset

func reset_transform():
	global_transform = original_transform