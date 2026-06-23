extends Node3D

@export_category("Button Setup")
@export var button: RigidBody3D
@export var left_button: bool = false
@export var right_button: bool = false

@export_category("Button Physics")
## How far down the button gets pushed (in local 3D units).
@export var press_depth: float = 0.3
## How fast the button presses down and springs back up.
@export var transition_speed: float = 0.15
## NEW: How long to wait after the player leaves before the button springs up.
@export var return_delay: float = 0.1

var base_y: float
var active_tween: Tween

# NEW: Prevents the player from spam-changing levels by wiggling on the trigger
var is_pressed: bool = false

func _ready() -> void:
	# Make sure the button is actually assigned in the inspector!
	if button:
		# Save the initial resting height of the button itself
		base_y = button.position.y
	else:
		push_error("Button RigidBody3D not assigned in ", name)

func _on_trigger_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and button:
		# LOGIC SPAM PROOF: Only trigger if the button has completely reset!
		if not is_pressed:
			is_pressed = true
			change_selected_level()
			
			# Animate down instantly (0.0 delay)
			animate_button(base_y - press_depth, 0.0)
		else:
			# If they step back on during the "return delay", 
			# just force the visual back down without changing the level again.
			animate_button(base_y - press_depth, 0.0)

func _on_trigger_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and button:
		# Tween the button back up, passing in our configurable delay
		animate_button(base_y, return_delay)

func animate_button(target_y: float, delay: float = 0.0) -> void:
	# 1. Interrupt any currently playing animation or waiting delay
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	# 2. Create a fresh tween
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. ANIMATION SPAM PROOF: Add the delay before moving
	if delay > 0.0:
		active_tween.tween_interval(delay)
	
	# 4. Animate the BUTTON's Y position
	active_tween.tween_property(button, "position:y", target_y, transition_speed)

	# 5. LOGIC RESET: If the button is heading back to its original top position,
	# unlock the button so it can be pressed again, but ONLY after the animation completely finishes.
	if target_y == base_y:
		active_tween.tween_callback(func(): is_pressed = false)


func change_selected_level():
	if left_button and not right_button:
		if PlayerGlobals.selected_level - 1 > 0:
			PlayerGlobals.selected_level -= 1
		else:
			PlayerGlobals.selected_level = 5
	
	if right_button and not left_button:
		if PlayerGlobals.selected_level < PlayerGlobals.total_levels:
			PlayerGlobals.selected_level += 1
		else:
			PlayerGlobals.selected_level = 1