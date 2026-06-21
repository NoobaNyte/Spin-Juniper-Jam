extends Camera3D

@export_category("Targeting")
@export var player: CharacterBody3D

@export_category("Follow Speeds")
## How aggressively the camera tracks left/right movement.
@export var smooth_speed_x: float = 4.0
## How fast the camera zooms in/out on the Z-axis when breached.
@export var smooth_speed_z: float = 2.0
## How fast the camera transitions into your future special areas.
@export var transition_speed: float = 3.0

@export_category("Dynamic Z-Axis Mechanics")
## The default Z distance the camera sits away from the player.
@export var base_z_offset: float = -11.0
## If the distance between the player and camera exceeds this, it triggers the zoom.
@export var z_breach_threshold: float = 15.0
## The new, closer Z distance the camera targets when the breach happens.
@export var zoomed_in_z_offset: float = -5.0

@export_category("Future: Special Areas")
## Where the camera should sit when the player enters a special zone.
@export var special_area_offset: Vector3 = Vector3(0, 15, -15)
## The rotation (in degrees) the camera should tilt to in the special zone.
@export var special_area_rotation_deg: Vector3 = Vector3(-45, 0, 0)

# --- Internal Variables ---
var is_in_special_area: bool = false
var locked_y_height: float
var base_rotation: Vector3
var current_z_target: float

func _ready() -> void:
	# Forces the camera to act independently in world space, 
	# preventing jitter if it accidentally inherits parent movement.
	top_level = true
	
	# Store the starting height and rotation to lock them in place normally
	locked_y_height = global_position.y
	base_rotation = rotation
	current_z_target = base_z_offset

func _physics_process(delta: float) -> void:
	if not player:
		return

	if is_in_special_area:
		# =======================================================
		# FUTURE FEATURE: Special Area Override (Zoom out & Tilt)
		# =======================================================
		var target_pos = player.global_position + special_area_offset
		var target_rot = Vector3(
			deg_to_rad(special_area_rotation_deg.x),
			deg_to_rad(special_area_rotation_deg.y),
			deg_to_rad(special_area_rotation_deg.z)
		)
		
		# Smoothly move everything to the special area settings
		global_position = global_position.lerp(target_pos, transition_speed * delta)
		rotation.x = lerp_angle(rotation.x, target_rot.x, transition_speed * delta)
		rotation.y = lerp_angle(rotation.y, target_rot.y, transition_speed * delta)
		rotation.z = lerp_angle(rotation.z, target_rot.z, transition_speed * delta)
		
	else:
		# =======================================================
		# NORMAL BEHAVIOR: Left/Right Follow & Dynamic Z-Breach
		# =======================================================
		# 1. Left and Right Only Follow (X-Axis & Locked Y-Axis)
		global_position.x = lerp(global_position.x, player.global_position.x, smooth_speed_x * delta)
		global_position.y = lerp(global_position.y, locked_y_height, transition_speed * delta)
		
		# 2. Dynamic Z-Breach Logic
		var distance_to_player_z = abs(global_position.z - player.global_position.z)
		
		if distance_to_player_z > z_breach_threshold:
			# Player breached! Shift our target to the zoomed-in offset
			current_z_target = lerp(current_z_target, zoomed_in_z_offset, smooth_speed_z * delta)
		else:
			# Player is in a safe range, relax back to the base distance
			current_z_target = lerp(current_z_target, base_z_offset, smooth_speed_z * delta)
			
		# Apply the dynamic Z movement
		var desired_z_position = player.global_position.z + current_z_target
		global_position.z = lerp(global_position.z, desired_z_position, smooth_speed_z * delta)
		
		# Lock rotation back to normal just in case they just exited a special area
		rotation.x = lerp_angle(rotation.x, base_rotation.x, transition_speed * delta)
		rotation.y = lerp_angle(rotation.y, base_rotation.y, transition_speed * delta)
		rotation.z = lerp_angle(rotation.z, base_rotation.z, transition_speed * delta)

# =======================================================
# PUBLIC METHODS (Call these from your Area3D later!)
# =======================================================

func trigger_special_area() -> void:
	is_in_special_area = true

func exit_special_area() -> void:
	is_in_special_area = false

func _on_zoom_area_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
