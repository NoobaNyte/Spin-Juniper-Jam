extends RigidBody3D
class_name BaseFallingObject

var going_to_be_destroyed: bool = false

func _ready() -> void:
	PlayerGlobals.reset_game.connect(destroy_after_cooldown)

func destroy_after_cooldown():
	if not going_to_be_destroyed:
		print("queing for destroy")
		going_to_be_destroyed = true
		await get_tree().create_timer(2).timeout # wait for object to get offscreen a bit
		queue_free()
