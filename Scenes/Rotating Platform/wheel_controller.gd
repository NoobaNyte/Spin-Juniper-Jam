extends Node

var all_pieces: Node3D

func _ready() -> void:
	all_pieces = owner.find_child("AllPieces", true, false)
	wheel_startup()

func wheel_startup():
	WheelGlobals.rotation_speed = 600
	await get_tree().create_timer(0.2).timeout
	WheelGlobals.rotation_speed = WheelGlobals.preview_rotation_speed

func _process(delta: float) -> void:
	if all_pieces:
		all_pieces.rotation.z += deg_to_rad(WheelGlobals.rotation_speed) * delta
