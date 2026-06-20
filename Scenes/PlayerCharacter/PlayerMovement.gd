extends CharacterBody3D

# ── Movement Settings ──────────────────────────────────────────────────────────
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 18.0

# ── Jump Settings ──────────────────────────────────────────────────────────────
@export var jump_velocity: float = 8.0
@export var gravity_scale: float = 2.5       # Snappier feel; 1.0 = default gravity
@export var jump_buffer_time: float = 0.12   # Seconds of jump input buffering
@export var coyote_time: float = 0.07        # Seconds of grace after walking off edge where you can still jump

# ── Platform Riding ────────────────────────────────────────────────────────────
# The rotating platform's RigidBody3D (assign in Inspector or via code)
@export var platform: Node3D = null

# Internal state
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_buffer: float = 0.0
var _coyote_timer: float = 0.0
var _was_on_floor: bool = false

# Velocity contributed by the platform this frame
var _platform_velocity: Vector3 = Vector3.ZERO

# Track player's position relative to the platform each frame for delta movement
var _last_platform_xform: Transform3D = Transform3D.IDENTITY
var _was_on_platform: bool = false


func _physics_process(delta: float) -> void:
	_update_platform_velocity(delta)
	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_jump()
	_handle_movement(delta)
	_apply_platform_velocity()

	move_and_slide()

	_was_on_floor = is_on_floor()


# ── Platform Riding ────────────────────────────────────────────────────────────

func _update_platform_velocity(delta: float) -> void:
	_platform_velocity = Vector3.ZERO

	if platform == null:
		_was_on_platform = false
		return

	if not is_on_floor():
		_was_on_platform = false
		return

	var current_xform: Transform3D = platform.global_transform

	if _was_on_platform:
		# Express our current world position in the platform's LOCAL space from
		# last frame, then transform it to world space via THIS frame's transform.
		# The difference is exactly how much the platform moved us.
		var local_pos: Vector3 = _last_platform_xform.affine_inverse() * global_position
		var new_world_pos: Vector3 = current_xform * local_pos
		_platform_velocity = (new_world_pos - global_position) / delta

	_last_platform_xform = current_xform
	_was_on_platform = true


func _apply_platform_velocity() -> void:
	# Inject horizontal platform delta; vertical is handled by gravity/jump.
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
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer = max(_jump_buffer - delta, 0.0)


func _handle_jump() -> void:
	var can_jump: bool = is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote_timer = 0.0


# ── Directional Movement (camera-relative, top-down fixed camera) ──────────────
# The camera looks straight down (or near-top-down), so:
#   "up"    on screen  →  -Z in world  (forward)
#   "down"  on screen  →  +Z in world  (back)
#   "left"  on screen  →  -X in world
#   "right" on screen  →  +X in world
# If your camera is rotated around Y, replace wish_dir with a version
# rotated by the camera's Y angle (see comments below).

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")   # up = -1, down = +1

	# Map 2-D screen input to 3-D world horizontal plane
	var wish_dir := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	# ── Optional: rotate wish_dir to match a non-axis-aligned camera ──────────
	# Uncomment if your camera is rotated around Y:
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
