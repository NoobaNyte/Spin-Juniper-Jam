extends CharacterBody3D

# ── Animation Settings ──────────────────────────────────────────────────────────
@export var animation_player: AnimationPlayer
@export var anim_blend_time: float = 0.25

@export_group("Animation Speeds")
@export var speed_idle: float = 1.0
@export var speed_running: float = 2.0
@export var speed_walking: float = 1.0
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

# ── Footstep Settings ──────────────────────────────────────────────────────────
@export_group("Footsteps")
@export var footstep_rate: float = 0.16 # seconds between footsteps at full speed

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_buffer: float = 0.0
var _coyote_timer: float = 0.0
var _was_on_floor: bool = false
var _footstep_timer: float = 0.0

func _ready() -> void:
	PlayerGlobals.set_move_speed.connect(SetPlayerMaxSpeed)
	PlayerGlobals.increase_move_speed.connect(IncreasePlayerMaxSpeed)
	PlayerGlobals.set_rotation_speed.connect(SetPlayerRotationSpeed)
	PlayerGlobals.increase_rotation_speed.connect(IncreasePlayerRotationSpeed)
	PlayerGlobals.set_acceleration.connect(SetPlayerAcceleration)
	PlayerGlobals.increase_acceleration.connect(IncreasePlayerAcceleration)
	PlayerGlobals.set_jump_velocity.connect(SetPlayerJumpVelocity)
	PlayerGlobals.increase_jump_velocity.connect(IncreasePlayerJumpVelocity)
	PlayerGlobals.set_friction.connect(SetPlayerFriction)


func _physics_process(delta: float) -> void:
	var wish_dir := Vector3.ZERO

	if not PlayerGlobals.disable_movement:
		var input_dir := Vector2.ZERO
		input_dir.y = Input.get_axis("MoveRight", "MoveLeft")
		input_dir.x = Input.get_axis("MoveUp", "MoveDown")
		wish_dir = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
		wish_dir = wish_dir.rotated(Vector3.UP, PI / 2.0)

	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_jump()
	_handle_movement(delta, wish_dir)
	_handle_rotation(delta, wish_dir)
	_handle_animations(wish_dir)
	_handle_footsteps(delta, wish_dir)

	move_and_slide()

	if not _was_on_floor and is_on_floor():
		AudioGlobals.play_jump_landing_sfx()

	_was_on_floor = is_on_floor()

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
	if Input.is_action_just_pressed("Jump") and not PlayerGlobals.disable_movement:
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer = max(_jump_buffer - delta, 0.0)

func _handle_jump() -> void:
	var can_jump: bool = is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		AudioGlobals.play_jump_sfx()
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote_timer = 0.0

func _handle_movement(delta: float, wish_dir: Vector3) -> void:
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

func _handle_animations(wish_dir: Vector3) -> void:
	if not animation_player: return

	var target_anim: String = "Armature|Idle"
	var target_speed: float = speed_idle

	if not is_on_floor():
		target_anim = "Armature|Jump"
		target_speed = speed_jump
	elif wish_dir != Vector3.ZERO:
		target_anim = "Armature|Running"
		target_speed = speed_running

	if animation_player.current_animation != target_anim:
		animation_player.play(target_anim, anim_blend_time, target_speed)

func _handle_footsteps(delta: float, wish_dir: Vector3) -> void:
	# No footsteps if airborne or standing still
	if not is_on_floor() or wish_dir == Vector3.ZERO:
		_footstep_timer = 0.0
		return

	_footstep_timer += delta
	var interval := footstep_rate
	if _footstep_timer >= interval:
		_footstep_timer = fmod(_footstep_timer, interval)
		AudioGlobals.play_random_footstep_sfx()


# ================================================================================================================
# ------------------------------------- GLOBAL API FUNCTIONS BELOW HERE ------------------------------------------
# ================================================================================================================

func SetPlayerMaxSpeed(speed: float) -> void:
	move_speed = speed
	return
	
func IncreasePlayerMaxSpeed(speed: float) -> void:
	move_speed += speed
	return

func SetPlayerRotationSpeed(speed: float) -> void:
	rotation_speed = speed
	return
	
func IncreasePlayerRotationSpeed(speed: float) -> void:
	rotation_speed += speed
	return

func SetPlayerAcceleration(accel: float) -> void:
	acceleration = accel
	return

func IncreasePlayerAcceleration(accel: float) -> void:
	acceleration += accel
	return
	
func SetPlayerJumpVelocity(vel: float) -> void:
	jump_velocity = vel
	return

func IncreasePlayerJumpVelocity(vel: float) -> void:
	jump_velocity += vel
	return

func SetPlayerFriction(frict: float) -> void:
	friction = frict
	return

func IncreasePlayerFriction(frict: float) -> void:
	friction += frict
	return
