extends CharacterBody3D

# ── Movement Settings ──────────────────────────────────────────────────────────
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 18.0

# ── Jump Settings ──────────────────────────────────────────────────────────────
@export var jump_velocity: float = 8.0
@export var gravity_scale: float = 2.5       # Snappier feel; 1.0 = default gravity
@export var jump_buffer_time: float = 0.12   # Seconds of jump input buffering
@export var coyote_time: float = 0.07        # Seconds of grace after walking off edge

# ── Platform Riding ────────────────────────────────────────────────────────────
# World-space point all platform pieces rotate around. Set this at runtime
# when you spawn the platform, e.g. player.pivot_point = platform_center
@export var pivot_point: Vector3 = Vector3.ZERO

# Internally tracked — updated automatically from collision data each frame
var _current_platform: RigidBody3D = null

# Internal state
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_buffer: float = 0.0
var _coyote_timer: float = 0.0
var _was_on_floor: bool = false
var _platform_velocity: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	_detect_platform()
	_update_platform_velocity()
	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_jump()
	_handle_movement(delta)
	_apply_platform_velocity()

	move_and_slide()

	_was_on_floor = is_on_floor()


# ── Platform Auto-Detection ────────────────────────────────────────────────────
# Reads collision results from the previous move_and_slide() call to find
# whichever RigidBody3D the player is standing on right now.

func _detect_platform() -> void:
	if not is_on_floor():
		_current_platform = null
		return

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is RigidBody3D:
			# Only count it as the floor platform if the contact normal
			# points generally upward (not a wall hit)
			if col.get_normal().y > 0.5:
				if collider != _current_platform:
					_current_platform = collider
				return

	# Stood on something that isn't a RigidBody3D (e.g. a StaticBody floor)
	_current_platform = null


# ── Platform Velocity ──────────────────────────────────────────────────────────
# Uses the platform's angular velocity around the shared pivot to compute
# the tangential velocity at the player's position.
# Only X and Z are applied — gravity owns Y.

func _update_platform_velocity() -> void:
	_platform_velocity = Vector3.ZERO

	if _current_platform == null or not is_on_floor():
		return

	# Vector from the pivot to the player in the horizontal plane
	var to_player := global_position - pivot_point
	to_player.y = 0.0  # flatten — we only want horizontal tangential velocity

	# Angular velocity of the rigid body (world space, rad/s)
	# For a platform spinning around the world Y axis this is typically (0, ω, 0)
	var ang_vel: Vector3 = _current_platform.angular_velocity

	# Tangential velocity = ω × r  (cross product gives the perpendicular velocity)
	var tangential: Vector3 = ang_vel.cross(to_player)

	# Zero out vertical component — let gravity handle Y
	_platform_velocity = Vector3(tangential.x, 0.0, tangential.z)


func _apply_platform_velocity() -> void:
	velocity.x += _platform_velocity.x
	velocity.z += _platform_velocity.z


# ── Gravity ────────────────────────────────────────────────────────────────────

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta


# ── Coyote Time ────────────────────────────────────────────────────────────────

func _handle_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor():
		_coyote_timer = coyote_time
	elif is_on_floor():
		_coyote_timer = 0.0
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)


# ── Jump Buffering ─────────────────────────────────────────────────────────────

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


# ── Directional Movement ───────────────────────────────────────────────────────

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.y = Input.get_axis("MoveRight", "MoveLeft")
	input_dir.x = Input.get_axis("MoveUp", "MoveDown")

	var wish_dir := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	# ── Optional: rotate wish_dir to match a non-axis-aligned camera ──────────
	# var cam_basis := get_viewport().get_camera_3d().global_transform.basis
	# var cam_forward := -cam_basis.z
	# cam_forward.y = 0.0
	# cam_forward = cam_forward.normalized()
	# var cam_right := cam_basis.x
	# cam_right.y = 0.0
	# cam_right = cam_right.normalized()
	# wish_dir = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()
	# ──────────────────────────────────────────────────────────────────────────

	if wish_dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, wish_dir.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, wish_dir.z * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
