extends Camera3D

@export_category("Targeting")
@export var player: CharacterBody3D
@export var zoom_pos: Camera3D
@export var playing_pos: Camera3D # NEW: The static position to play the game from

@export_category("Follow Speeds")
@export var max_smooth_speed_x: float = 4.0
@export var max_smooth_speed_z: float = 2.0
@export var max_transition_speed: float = 1.5

@export_category("Easing Mechanics")
## How softly the camera ramps up to full speed (lower = softer ease-in)
@export var acceleration: float = 2.0

@export_category("Dynamic Z-Axis Mechanics")
@export var base_z_offset: float = -11.0
@export var z_breach_threshold: float = 15.0
@export var zoomed_in_z_offset: float = -5.0

# --- Internal Variables ---
var is_in_special_area: bool = false
var locked_local_y: float
var base_local_rotation: Vector3
var current_z_target: float

# Dynamic speeds that ramp up to create the Ease-In effect
var current_speed_x: float = 0.0
var current_speed_z: float = 0.0
var current_trans_speed: float = 0.0

var playing_tween: Tween # NEW: Tracks the transition animation

var detached_from_player: bool = false:
	set(value):
		detached_from_player = value
		if detached_from_player:
			current_trans_speed = 0.0
			current_speed_x = 0.0
			current_speed_z = 0.0

func _ready() -> void:
	locked_local_y = position.y
	base_local_rotation = rotation
	current_z_target = base_z_offset

func _physics_process(delta: float) -> void:
	if not player or detached_from_player:
		return

	current_trans_speed = lerp(current_trans_speed, max_transition_speed, acceleration * delta)

	if is_in_special_area and zoom_pos:
		global_transform = global_transform.interpolate_with(zoom_pos.global_transform, current_trans_speed * delta)
		
	else:
		current_speed_x = lerp(current_speed_x, max_smooth_speed_x, acceleration * delta)
		current_speed_z = lerp(current_speed_z, max_smooth_speed_z, acceleration * delta)
		
		var scene_node = get_parent()
		var target_local_pos = scene_node.to_local(player.global_position)
		
		# 1. Left/Right Follow using LOCAL position
		position.x = lerp(position.x, target_local_pos.x, current_speed_x * delta)
		position.y = lerp(position.y, locked_local_y, current_trans_speed * delta)
		
		# 2. Dynamic Z-Breach Logic using LOCAL Z
		var distance_to_player_z = abs(position.z - target_local_pos.z)
		
		if distance_to_player_z > z_breach_threshold:
			current_z_target = lerp(current_z_target, zoomed_in_z_offset, current_speed_z * delta)
		else:
			current_z_target = lerp(current_z_target, base_z_offset, current_speed_z * delta)
			
		var desired_z_position = target_local_pos.z + current_z_target
		position.z = lerp(position.z, desired_z_position, current_speed_z * delta)
		
		# Softly rotate back to the normal local rotation
		rotation.x = lerp_angle(rotation.x, base_local_rotation.x, current_trans_speed * delta)
		rotation.y = lerp_angle(rotation.y, base_local_rotation.y, current_trans_speed * delta)
		rotation.z = lerp_angle(rotation.z, base_local_rotation.z, current_trans_speed * delta)


# =======================================================
# NEW: EXTERNAL CAMERA TRIGGERS
# =======================================================

func toggle_playing_camera(is_playing: bool, transition_time: float = 2.5) -> void:
	# Stop any current camera animation so they don't fight
	if playing_tween and playing_tween.is_valid():
		playing_tween.kill()
		
	if is_playing:
		# 1. Freeze the normal physics follow logic
		detached_from_player = true
		
		if playing_pos:
			# 2. Smoothly tween to the exact global position and rotation of the playing_pos
			playing_tween = create_tween().set_parallel(true)
			
			# TRANS_CUBIC + EASE_IN_OUT makes it start slow, speed up, and slow down perfectly at the end
			playing_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
			playing_tween.tween_property(self, "position", playing_pos.position, transition_time)
			playing_tween.tween_property(self, "rotation", playing_pos.rotation, transition_time)
	else:
		# 1. Zero out the speeds BEFORE giving control back to the physics loop
		# This ensures the camera doesn't violently snap back to the player!
		current_trans_speed = 0.0
		current_speed_x = 0.0
		current_speed_z = 0.0
		
		# 2. Give control back to the normal camera system
		detached_from_player = false

# =======================================================
# SIGNAL HOOKUPS
# =======================================================

func _on_zoom_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_in_special_area = true
		current_trans_speed = 0.0

func _on_zoom_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_in_special_area = false
		current_trans_speed = 0.0
		current_speed_x = 0.0
		current_speed_z = 0.0