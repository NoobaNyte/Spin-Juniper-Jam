extends RigidBody3D

var height: float = 1.0

func _ready() -> void:
	##set_height()
	pass

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
