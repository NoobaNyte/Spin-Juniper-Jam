extends CharacterBody3D

# ── Animation Settings ──────────────────────────────────────────────────────────
@export var animation_player: AnimationPlayer

# ── Movement Settings ──────────────────────────────────────────────────────────
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 18.0

# ── Jump Settings ──────────────────────────────────────────────────────────────
@export var jump_velocity: float = 8.0
@export var gravity_scale: float = 2.5
@export var jump_buffer_time: float = 0.12
@export var coyote_time: float = 0.07

# ── Platform Riding ────────────────────────────────────────────────────────────
@export var pivot_point: Vector3 = Vector3.ZERO
@export var carry_decay: float = 3.0

var _current_platform: RigidBody3D = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_buffer: float = 0.0
var _coyote_timer: float = 0.0
var _was_on_floor: bool = false

# The angular offset of the player relative to the platform at the moment
# they landed. We add the platform's cumulative rotation to this each frame
# to find where they should be.
var _on_platform: bool = false
var _platform_angle_on_land: float = 0.0 # platform cumulative angle when landed
var _player_angle_on_land: float = 0.0 # player's world angle when landed
var _player_radius: float = 0.0 # player's distance from pivot when landed
var _platform_cumulative_angle: float = 0.0 # integrated from angular_velocity each frame

# Carry momentum when leaving platform
var _carry_velocity: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	_detect_platform()

	if _current_platform != null:
		_platform_cumulative_angle += _current_platform.angular_velocity.y * delta

	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_jump()
	_handle_movement(delta)

	if _on_platform and _current_platform != null and is_on_floor():
		var platform_rotation: float = _platform_cumulative_angle - _platform_angle_on_land
		var current_angle: float = _player_angle_on_land + platform_rotation
		var prev_x: float = global_position.x
		var prev_z: float = global_position.z
		global_position.x = pivot_point.x + sin(current_angle) * _player_radius
		global_position.z = pivot_point.z - cos(current_angle) * _player_radius
		_carry_velocity = Vector3(
			(global_position.x - prev_x) / delta,
			0.0,
			(global_position.z - prev_z) / delta
		)

	move_and_slide()

	var on_platform_now: bool = is_on_floor() and _current_platform != null

	if on_platform_now and not _on_platform:
		# Just landed — record reference angles and radius, clear carry
		var to_player := global_position - pivot_point
		to_player.y = 0.0
		_player_radius = to_player.length()
		_player_angle_on_land = atan2(to_player.x, -to_player.z)
		_platform_angle_on_land = _platform_cumulative_angle
		_carry_velocity = Vector3.ZERO
		velocity.x = 0.0
		velocity.z = 0.0

	elif _on_platform and not on_platform_now:
		# Just left the platform — bake carry into velocity exactly once
		velocity.x += _carry_velocity.x
		velocity.z += _carry_velocity.z

	elif not on_platform_now:
		# Already airborne — just decay, never add to velocity again
		_carry_velocity = _carry_velocity.move_toward(Vector3.ZERO, carry_decay * delta)

	_on_platform = on_platform_now
	_was_on_floor = is_on_floor()


func _detect_platform() -> void:
	if not is_on_floor():
		_current_platform = null
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is RigidBody3D and col.get_normal().y > 0.5:
			_current_platform = collider
			return
	_current_platform = null


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta


func _handle_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor():
		_coyote_timer = coyote_time
	elif is_on_floor():
		_coyote_timer = 0.0
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)


func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer = max(_jump_buffer - delta, 0.0)


func _handle_jump() -> void:
	var can_jump: bool = is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote_timer = 0.0


func _handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.y = Input.get_axis("MoveRight", "MoveLeft")
	input_dir.x = Input.get_axis("MoveUp", "MoveDown")
	var wish_dir := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	if _on_platform and _current_platform != null:
		# Update the stored angle and radius to reflect player input
		# so movement is relative to the rotating platform
		if wish_dir != Vector3.ZERO:
			var to_player := global_position - pivot_point
			to_player.y = 0.0
			# Move in world space, then re-derive polar coords so platform
			# rotation stays in sync next frame
			var new_pos := to_player + wish_dir * move_speed * delta
			_player_radius = new_pos.length()
			var platform_rotation: float = _platform_cumulative_angle - _platform_angle_on_land
			_player_angle_on_land = atan2(new_pos.x, -new_pos.z) - platform_rotation
	else:
		if wish_dir != Vector3.ZERO:
			velocity.x = move_toward(velocity.x, wish_dir.x * move_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, wish_dir.z * move_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)
