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

var base_y: float
var active_tween: Tween

func _ready() -> void:
	# Make sure the button is actually assigned in the inspector!
	if button:
		# Save the initial resting height of the button itself
		base_y = button.position.y
	else:
		push_error("Button RigidBody3D not assigned in ", name)

func _on_trigger_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and button:
		change_selected_level()
		animate_button(base_y - press_depth)
		

func _on_trigger_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and button:
		# Tween the button back up
		animate_button(base_y)

func animate_button(target_y: float) -> void:
	# 1. Interrupt any currently playing animation
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	# 2. Create a fresh tween
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. Animate the BUTTON's Y position, not the root node
	active_tween.tween_property(button, "position:y", target_y, transition_speed)

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