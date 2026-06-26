class_name RandomZenCmd
extends BaseLevelCommand

@export var seconds: float = 600.0

# How often (in seconds) a new random command fires
@export var min_interval: float = 5.0
@export var max_interval: float = 20.0

# --- SetGapChanceCmd range ---
@export var enable_gap_chance: bool = true
@export var gap_chance_min: int = 0
@export var gap_chance_max: int = 50

# --- SetGapSizesCmd range ---
@export var enable_gap_sizes: bool = true
@export var min_gap_angle_size_min: int = 5
@export var min_gap_angle_size_max: int = 15
@export var max_gap_angle_size_min: int = 20
@export var max_gap_angle_size_max: int = 45

# --- SetPieceAngleSizesCmd range ---
@export var enable_piece_angle_sizes: bool = true
@export var min_piece_angle_min: int = 30
@export var min_piece_angle_max: int = 60
@export var max_piece_angle_min: int = 61
@export var max_piece_angle_max: int = 90

# --- SetWallGenChanceCmd range ---
@export var enable_wall_gen_chance: bool = true
@export var wall_gen_chance_min: int = 0
@export var wall_gen_chance_max: int = 30

# --- SetWheelSpeedCmd / TransitionWheelSpeedCmd range ---
@export var enable_speed_changes: bool = true
@export var speed_min: float = 10.0
@export var speed_max: float = 80.0
@export var use_transition_for_speed: bool = true # false = instant SetWheelSpeedCmd
@export var transition_duration_min: float = 5.0
@export var transition_duration_max: float = 20.0

# --- SpawnFallingObjectsCmd ---
@export var enable_spawning: bool = false # off unless you wire up scenes
@export var spawn_quantity_min: int = 3
@export var spawn_quantity_max: int = 15
@export var spawn_over_seconds_min: float = 2.0
@export var spawn_over_seconds_max: float = 8.0
@export var spawn_velocity_min: float = 0.0
@export var spawn_velocity_max: float = 5.0
@export var spawn_objects: Array[PackedScene] # populate in the Inspector

func check_time():
	total_command_time = seconds

func execute(_owner: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var elapsed: float = 0.0

	while elapsed < seconds:
		var interval: float = rng.randf_range(min_interval, max_interval)
		interval = minf(interval, seconds - elapsed)

		await _owner.get_tree().create_timer(interval).timeout

		if PlayerGlobals.lost_level:
			return

		elapsed += interval

		if elapsed >= seconds:
			break

		_fire_random_command(rng)

func _fire_random_command(rng: RandomNumberGenerator) -> void:
	# Build the pool of enabled command IDs
	var pool: Array[int] = []
	if enable_gap_chance: pool.append(0)
	if enable_gap_sizes: pool.append(1)
	if enable_piece_angle_sizes: pool.append(2)
	if enable_wall_gen_chance: pool.append(3)
	if enable_speed_changes: pool.append(4)
	if enable_spawning and spawn_objects.size() > 0:
		pool.append(5)

	if pool.is_empty():
		return

	match pool[rng.randi() % pool.size()]:
		0: # SetGapChanceCmd
			WheelGlobals.empty_piece_chance = rng.randi_range(gap_chance_min, gap_chance_max)

		1: # SetGapSizesCmd
			var lo := rng.randi_range(min_gap_angle_size_min, min_gap_angle_size_max)
			var hi := rng.randi_range(max_gap_angle_size_min, max_gap_angle_size_max)
			WheelGlobals.min_gap_angle_size = lo
			WheelGlobals.max_gap_angle_size = hi

		2: # SetPieceAngleSizesCmd
			var lo := rng.randi_range(min_piece_angle_min, min_piece_angle_max)
			var hi := rng.randi_range(max_piece_angle_min, max_piece_angle_max)
			WheelGlobals.min_piece_angle_size = lo
			WheelGlobals.max_piece_angle_size = hi

		3: # SetWallGenChanceCmd
			WheelGlobals.wall_gen_chance = rng.randi_range(wall_gen_chance_min, wall_gen_chance_max)

		4: # SetWheelSpeedCmd or TransitionWheelSpeedCmd
			var target := rng.randf_range(speed_min, speed_max)
			if use_transition_for_speed:
				var dur := rng.randf_range(transition_duration_min, transition_duration_max)
				# Fire-and-forget: don't await so the timer loop keeps running
				WheelGlobals.speed_transition(target, dur)
			else:
				WheelGlobals.rotation_speed = target

		5: # SpawnFallingObjectsCmd
			var qty := rng.randi_range(spawn_quantity_min, spawn_quantity_max)
			var over := rng.randf_range(spawn_over_seconds_min, spawn_over_seconds_max)
			var vmin := spawn_velocity_min
			var vmax := spawn_velocity_max
			WheelGlobals.spawn_falling_objects.emit(qty, over, spawn_objects, vmin, vmax)
