extends Node3D

@export_category("Button Setup")
@export var button: RigidBody3D
@export var left_button: bool = false
@export var right_button: bool = false

@export_category("Button Physics")
@export var press_depth: float = 0.3
@export var transition_speed: float = 0.15
@export var return_delay: float = 0.1

@export_category("Speed Boost")
@export var target_speed: float = 800.0
@export var ease_in_duration: float = 0.4
@export var hold_duration: float = 0.25
@export var ease_out_duration: float = 0.5

var base_y: float
var active_tween: Tween
var speed_tween: Tween
var is_on_cooldown: bool = false
var is_pressed: bool = false
var original_speed: float = 0.0
var body_on_button: bool = false

func _ready() -> void:
	if button:
		base_y = button.position.y
	else:
		push_error("Button RigidBody3D not assigned in ", name)

func _on_trigger_area_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player") or not button:
		return
	
	body_on_button = true

	if is_on_cooldown:
		return

	if not is_pressed:
		AudioGlobals.play_button_press_down_sfx()
		is_pressed = true
		is_on_cooldown = true
		original_speed = WheelGlobals.rotation_speed
		animate_button(base_y - press_depth, 0.0)
		trigger_speed_boost()

func _on_trigger_area_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Player") or not button:
		return

	body_on_button = false

	# only spring up if cooldown is done
	if not is_on_cooldown:
		animate_button(base_y, return_delay)

func trigger_speed_boost() -> void:
	if speed_tween and speed_tween.is_valid():
		speed_tween.kill()

	speed_tween = create_tween()

	# ease in to target speed
	speed_tween.tween_method(
		func(val: float): WheelGlobals.rotation_speed = val,
		WheelGlobals.rotation_speed,
		target_speed,
		ease_in_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# trigger level change exactly when ease-in finishes
	speed_tween.tween_callback(func(): change_selected_level())

	# hold at target speed
	speed_tween.tween_interval(hold_duration)

	# ease back to original speed
	speed_tween.tween_method(
		func(val: float): WheelGlobals.rotation_speed = val,
		target_speed,
		original_speed,
		ease_out_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# cooldown lifted after fully eased back
	speed_tween.tween_callback(func():
		is_on_cooldown = false
		is_pressed = false
		if not body_on_button:
			animate_button(base_y, return_delay)
		await get_tree().create_timer(0.1).timeout
		AudioGlobals.play_button_press_up_sfx()
	)

func animate_button(target_y: float, delay: float = 0.0) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if delay > 0.0:
		active_tween.tween_interval(delay)

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
