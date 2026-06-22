extends RichTextLabel

func _ready() -> void:
	if InputMap.has_action("Interact"):
		var events = InputMap.action_get_events("Interact")
		
		for event in events:
			if event is InputEventKey:
				# 1. Grab the raw integer ID of the physical key
				var key_id = event.physical_keycode
				
				# 2. Fallback: If physical_keycode is 0, they mapped a standard keycode
				if key_id == 0:
					key_id = event.keycode
					
				# 3. Translate that raw ID into a completely clean string (e.g., "E")
				text = OS.get_keycode_string(key_id)
				
				return
		
		text = "[?]"
	else:
		push_error("The action 'Interact' is missing from the Input Map!")