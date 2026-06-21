extends Camera3D

@export_category("Targeting")
@export var player: CharacterBody3D
@export var zoom_pos: Camera3D

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
var locked_y_height: float
var base_rotation: Vector3
var current_z_target: float

# Dynamic speeds that ramp up to create the Ease-In effect
var current_speed_x: float = 0.0
var current_speed_z: float = 0.0
var current_trans_speed: float = 0.0

func _ready() -> void:
	top_level = true
	
	locked_y_height = global_position.y
	base_rotation = rotation
	current_z_target = base_z_offset

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Always smoothly ramp the transition speed up toward its max value
	current_trans_speed = lerp(current_trans_speed, max_transition_speed, acceleration * delta)

	if is_in_special_area and zoom_pos:
		# =======================================================
		# SPECIAL AREA: Eased Quaternion Interpolation
		# =======================================================
		global_transform = global_transform.interpolate_with(zoom_pos.global_transform, current_trans_speed * delta)
		
	else:
		# =======================================================
		# NORMAL BEHAVIOR: Left/Right Follow & Dynamic Z-Breach
		# =======================================================
		# Ramp up our gameplay follow speeds
		current_speed_x = lerp(current_speed_x, max_smooth_speed_x, acceleration * delta)
		current_speed_z = lerp(current_speed_z, max_smooth_speed_z, acceleration * delta)
		
		# 1. Left and Right Only Follow (using the ramped speed)
		global_position.x = lerp(global_position.x, player.global_position.x, current_speed_x * delta)
		global_position.y = lerp(global_position.y, locked_y_height, current_trans_speed * delta)
		
		# 2. Dynamic Z-Breach Logic
		var distance_to_player_z = abs(global_position.z - player.global_position.z)
		
		if distance_to_player_z > z_breach_threshold:
			current_z_target = lerp(current_z_target, zoomed_in_z_offset, current_speed_z * delta)
		else:
			current_z_target = lerp(current_z_target, base_z_offset, current_speed_z * delta)
			
		var desired_z_position = player.global_position.z + current_z_target
		global_position.z = lerp(global_position.z, desired_z_position, current_speed_z * delta)
		
		# Softly rotate back to normal
		rotation.x = lerp_angle(rotation.x, base_rotation.x, current_trans_speed * delta)
		rotation.y = lerp_angle(rotation.y, base_rotation.y, current_trans_speed * delta)
		rotation.z = lerp_angle(rotation.z, base_rotation.z, current_trans_speed * delta)

# =======================================================
# SIGNAL HOOKUPS
# =======================================================

func _on_zoom_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_in_special_area = true
		# Instantly drop the speed to 0 so the physics process has to ramp it up!
		current_trans_speed = 0.0

func _on_zoom_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_in_special_area = false
		# Drop ALL speeds to 0 so the exit back to the player is also smooth
		current_trans_speed = 0.0
		current_speed_x = 0.0
		current_speed_z = 0.0