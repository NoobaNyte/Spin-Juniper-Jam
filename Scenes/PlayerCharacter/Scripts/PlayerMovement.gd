extends CharacterBody3D

# ── Movement Type Settings ──────────────────────────────────────────────────────────
@export var in_game: bool = true
@export var in_menu: bool = false

# ── Animation Settings ──────────────────────────────────────────────────────────
@export var animation_player: AnimationPlayer
@export var anim_blend_time: float = 0.25

@export_group("Animation Speeds")
@export var speed_idle: float = 1.0
@export var speed_running: float = 2.0
@export var speed_walking: float = 1.0 # walking is not hooked up rn because set movement speed
@export var speed_jump: float = 1.15

# ── Movement Settings ──────────────────────────────────────────────────────────
@export_group("Settings")
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 18.0
@export var rotation_speed: float = 12.0

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

# Platform memory variables
var _on_platform: bool = false
var _platform_angle_on_land: float = 0.0
var _player_angle_on_land: float = 0.0
var _player_radius: float = 0.0
var _platform_cumulative_angle: float = 0.0

# Carry momentum when leaving platform
var _carry_velocity: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	_detect_platform()

	if _current_platform != null:
		_platform_cumulative_angle += _current_platform.angular_velocity.y * delta

	# 1. Grab input
	var input_dir := Vector2.ZERO
	input_dir.y = Input.get_axis("MoveRight", "MoveLeft")
	input_dir.x = Input.get_axis("MoveUp", "MoveDown")
	var wish_dir := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	# Rotate inputs 90 degrees if in menu
	if in_menu:
		wish_dir = wish_dir.rotated(Vector3.UP, PI / 2.0)

	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_jump()
	_handle_movement(delta, wish_dir)
	_handle_rotation(delta, wish_dir)
	_handle_animations(wish_dir)

	# 2. Platform Polar Coordinate Math
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

	# 3. Platform momentum handling
	var on_platform_now: bool = is_on_floor() and _current_platform != null

	if on_platform_now and not _on_platform:
		var to_player := global_position - pivot_point
		to_player.y = 0.0
		_player_radius = to_player.length()
		_player_angle_on_land = atan2(to_player.x, -to_player.z)
		_platform_angle_on_land = _platform_cumulative_angle
		_carry_velocity = Vector3.ZERO
		velocity.x = 0.0
		velocity.z = 0.0

	elif _on_platform and not on_platform_now:
		velocity.x += _carry_velocity.x
		velocity.z += _carry_velocity.z

	elif not on_platform_now:
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


func _handle_movement(delta: float, wish_dir: Vector3) -> void:
	if _on_platform and _current_platform != null:
		if wish_dir != Vector3.ZERO:
			var to_player := global_position - pivot_point
			to_player.y = 0.0
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


func _handle_rotation(delta: float, wish_dir: Vector3) -> void:
	if wish_dir != Vector3.ZERO:
		var target_angle := atan2(wish_dir.x, wish_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)


# UPDATED: No more stuttering!
func _handle_animations(wish_dir: Vector3) -> void:
	if not animation_player:
		return
		
	var target_anim: String = "Armature|Idle"
	var target_speed: float = speed_idle
	
	if not is_on_floor():
		target_anim = "Armature|Jump"
		target_speed = speed_jump
	elif wish_dir != Vector3.ZERO:
		target_anim = "Armature|Running"
		target_speed = speed_running

	# Only call play if we are actually changing animations. 
	# This lets Godot's internal blending finish smoothly without being interrupted!
	if animation_player.current_animation != target_anim:
		animation_player.play(target_anim, anim_blend_time, target_speed)
