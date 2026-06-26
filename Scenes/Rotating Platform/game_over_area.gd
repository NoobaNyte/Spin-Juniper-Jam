extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		PlayerGlobals.playerCurrentHealth -= 1
		if(PlayerGlobals.playerCurrentHealth <= 0):
			PlayerGlobals.game_over.emit()
		PlayerGlobals.respawnPlayer()
	
	
	if body.is_in_group("FallingObject"):
		body.destroy_after_cooldown()
