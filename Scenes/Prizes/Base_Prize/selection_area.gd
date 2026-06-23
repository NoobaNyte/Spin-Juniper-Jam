extends Area3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		# Get all bodies currently inside this area
		var bodies = get_overlapping_bodies()
		
		# Check if the player is one of them
		for body in bodies:
			if body.is_in_group("Player"): # 'owner' refers to the Player CharacterBody3D
				if owner.has_method("buy_prize"):
					owner.buy_prize()
				else:
					print(owner.name)
					print("tried to buy item but could not because item does not have 'buy_prize' method")
