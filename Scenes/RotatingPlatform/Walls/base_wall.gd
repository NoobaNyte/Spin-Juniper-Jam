extends AnimatableBody3D

func _ready() -> void:
	$BaseWheel.queue_free()

	for child in get_children():
		if child is Node3D:
			child.rotation.x = deg_to_rad(-45.0)
			child.rotation.y = deg_to_rad(90)
			child.rotation.z = deg_to_rad(-90)
