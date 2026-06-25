extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		PlayerGlobals.game_over.emit()
	
	if body.is_in_group("FallingObject"):
		if body.is_class("BaseFallingObject"):
			if not body.going_to_be_destroyed:
				body.going_to_be_destroyed = true
				await get_tree().create_timer(2).timeout
				body.queue_free()
