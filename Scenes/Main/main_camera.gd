extends Camera3D

@export_category("Targeting")
@export var player: CharacterBody3D
@export var zoom_pos: Camera3D
@export var playing_pos: Camera3D

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

@export_category("Teleport Recovery")
@export var teleport_threshold: float = 5.0
@export var teleport_recovery_time: float = 1

# --- Internal Variables ---
var is_in_special_area: bool = false
var locked_local_y: float
var base_local_rotation: Vector3
var current_z_target: float

var current_speed_x: float = 0.0
var current_speed_z: float = 0.0
var current_trans_speed: float = 0.0

var playing_tween: Tween
var _teleport_tween: Tween
var _last_player_pos: Vector3 = Vector3.ZERO

var detached_from_player: bool = false:
	set(value):
		detached_from_player = value
		if detached_from_player:
			current_trans_speed = 0.0
			current_speed_x = 0.0
			current_speed_z = 0.0
			if _teleport_tween and _teleport_tween.is_valid():
				_teleport_tween.kill()
				_teleport_tween = null

func _ready() -> void:
	locked_local_y = position.y
	base_local_rotation = rotation
	current_z_target = base_z_offset
	PlayerGlobals.transition_to_wheel_view.connect(transition_to_wheel_view)

func _physics_process(delta: float) -> void:
	if not player:
		return

	if detached_from_player:
		# Keep last pos current so no false teleport detected when we re-attach
		_last_player_pos = player.global_position
		return

	# Teleport detection
	var player_delta: float = player.global_position.distance_to(_last_player_pos)
	if _last_player_pos != Vector3.ZERO and player_delta > teleport_threshold:
		_on_player_teleported()
	_last_player_pos = player.global_position

	# If teleport tween is active, skip normal follow logic
	if _teleport_tween and _teleport_tween.is_valid():
		return

	current_trans_speed = lerp(current_trans_speed, max_transition_speed, acceleration * delta)

	if is_in_special_area and zoom_pos:
		global_transform = global_transform.interpolate_with(zoom_pos.global_transform, current_trans_speed * delta)
	else:
		current_speed_x = lerp(current_speed_x, max_smooth_speed_x, acceleration * delta)
		current_speed_z = lerp(current_speed_z, max_smooth_speed_z, acceleration * delta)

		var scene_node = get_parent()
		var target_local_pos: Vector3 = scene_node.to_local(player.global_position)

		position.x = lerp(position.x, target_local_pos.x, current_speed_x * delta)
		position.y = lerp(position.y, locked_local_y, current_trans_speed * delta)

		var distance_to_player_z: float = abs(position.z - target_local_pos.z)

		if distance_to_player_z > z_breach_threshold:
			current_z_target = lerp(current_z_target, zoomed_in_z_offset, current_speed_z * delta)
		else:
			current_z_target = lerp(current_z_target, base_z_offset, current_speed_z * delta)

		var desired_z_position: float = target_local_pos.z + current_z_target
		position.z = lerp(position.z, desired_z_position, current_speed_z * delta)

		rotation.x = lerp_angle(rotation.x, base_local_rotation.x, current_trans_speed * delta)
		rotation.y = lerp_angle(rotation.y, base_local_rotation.y, current_trans_speed * delta)
		rotation.z = lerp_angle(rotation.z, base_local_rotation.z, current_trans_speed * delta)


# =======================================================
# EXTERNAL CAMERA TRIGGERS
# =======================================================

func toggle_playing_camera(is_playing: bool, transition_time: float = 2.5) -> void:
	if playing_tween and playing_tween.is_valid():
		playing_tween.kill()
	if _teleport_tween and _teleport_tween.is_valid():
		_teleport_tween.kill()
		_teleport_tween = null

	if is_playing:
		detached_from_player = true

		if playing_pos:
			playing_tween = create_tween().set_parallel(true)
			playing_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			playing_tween.tween_property(self, "position", playing_pos.position, transition_time)
			playing_tween.tween_property(self, "rotation", playing_pos.rotation, transition_time)
	else:
		current_trans_speed = 0.0
		current_speed_x = 0.0
		current_speed_z = 0.0
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

func _on_player_teleported() -> void:
	if _teleport_tween and _teleport_tween.is_valid():
		return

	current_speed_x = 0.0
	current_speed_z = 0.0
	current_trans_speed = 0.0

	var scene_node = get_parent()
	var target_local: Vector3 = scene_node.to_local(player.global_position)
	var target_pos: Vector3 = Vector3(target_local.x, position.y, target_local.z + current_z_target)

	_teleport_tween = create_tween().set_parallel(true)
	_teleport_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_teleport_tween.tween_property(self, "position", target_pos, teleport_recovery_time)


func transition_to_wheel_view(transition_time: float = 2.5) -> void:
	if playing_tween and playing_tween.is_valid():
		playing_tween.kill()
	if _teleport_tween and _teleport_tween.is_valid():
		_teleport_tween.kill()
		_teleport_tween = null

	detached_from_player = true

	if zoom_pos:
		playing_tween = create_tween().set_parallel(true)
		playing_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		playing_tween.tween_property(self, "position", zoom_pos.position, transition_time)
		playing_tween.tween_property(self, "rotation", zoom_pos.rotation, transition_time)
		playing_tween.chain().tween_callback(func():
			current_trans_speed = 0.0
			current_speed_x = 0.0
			current_speed_z = 0.0
			detached_from_player = false
		)
