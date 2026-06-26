extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if PlayerGlobals.game_ended:
			return
	
		# determine how much health to lose and emit sfx
		if is_in_group("WallArea"):
			AudioGlobals.play_wall_hit_sfx.emit()
			PlayerGlobals.playerCurrentHealth -= 1
				
		else:
			PlayerGlobals.playerCurrentHealth = 0
		
		# do things based on how much health
		if PlayerGlobals.playerCurrentHealth <= 0:
			if is_in_group("WallArea"):
				PlayerGlobals.fell = true

			PlayerGlobals.game_over.emit()
			PlayerGlobals.playerCurrentHealth = PlayerGlobals.hp_powerup_amount
			
			
		elif is_in_group("WallArea"):
				give_player_invincibility_frames()
	
	
	if body.is_in_group("FallingObject"):
		body.destroy_after_cooldown()

func give_player_invincibility_frames():
	PlayerGlobals.set_player_collision_layers.emit([2])
	PlayerGlobals.invincible = true
	await get_tree().create_timer(PlayerGlobals.playertIFrameSeconds).timeout
	PlayerGlobals.invincible = false
	PlayerGlobals.set_player_collision_layers.emit([1])
