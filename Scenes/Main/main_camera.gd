extends Camera3D

@export_category("Targeting")
@export var player: CharacterBody3D
@export var zoom_pos: Camera3D

@export_category("Follow Speeds")
@export var smooth_speed_x: float = 4.0
@export var smooth_speed_z: float = 2.0
# Dropped from 3.0 to 1.0 for a much longer, softer cinematic glide.
@export var transition_speed: float = 1.0

@export_category("Dynamic Z-Axis Mechanics")
@export var base_z_offset: float = -11.0
@export var z_breach_threshold: float = 15.0
@export var zoomed_in_z_offset: float = -5.0

# --- Internal Variables ---
var is_in_special_area: bool = false
var locked_y_height: float
var base_rotation: Vector3
var current_z_target: float

func _ready() -> void:
	top_level = true
	
	locked_y_height = global_position.y
	base_rotation = rotation
	current_z_target = base_z_offset

func _physics_process(delta: float) -> void:
	if not player:
		return

	if is_in_special_area and zoom_pos:
		# =======================================================
		# SPECIAL AREA: Quaternion Transform Interpolation
		# =======================================================
		# This one line handles Position, Rotation, and Scale simultaneously.
		# It uses Spherical Linear Interpolation (SLERP) for rotation, 
		# creating a flawless, natural curved motion to the dummy camera.
		global_transform = global_transform.interpolate_with(zoom_pos.global_transform, transition_speed * delta)
		
	else:
		# =======================================================
		# NORMAL BEHAVIOR: Left/Right Follow & Dynamic Z-Breach
		# =======================================================
		# 1. Left and Right Only Follow
		global_position.x = lerp(global_position.x, player.global_position.x, smooth_speed_x * delta)
		global_position.y = lerp(global_position.y, locked_y_height, transition_speed * delta)
		
		# 2. Dynamic Z-Breach Logic
		var distance_to_player_z = abs(global_position.z - player.global_position.z)
		
		if distance_to_player_z > z_breach_threshold:
			current_z_target = lerp(current_z_target, zoomed_in_z_offset, smooth_speed_z * delta)
		else:
			current_z_target = lerp(current_z_target, base_z_offset, smooth_speed_z * delta)
			
		var desired_z_position = player.global_position.z + current_z_target
		global_position.z = lerp(global_position.z, desired_z_position, smooth_speed_z * delta)
		
		# Softly rotate back to normal if exiting the special area
		rotation.x = lerp_angle(rotation.x, base_rotation.x, transition_speed * delta)
		rotation.y = lerp_angle(rotation.y, base_rotation.y, transition_speed * delta)
		rotation.z = lerp_angle(rotation.z, base_rotation.z, transition_speed * delta)

# =======================================================
# SIGNAL HOOKUPS
# =======================================================

func _on_zoom_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_in_special_area = true

func _on_zoom_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_in_special_area = false