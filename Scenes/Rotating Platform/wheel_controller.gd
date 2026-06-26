extends Node

@export var max_tick_rate: float = 20.0 # max ticks per second at high speed
@export var min_speed_threshold: float = 200.0 # below this rotation speed, no sfx
@export var speed_to_tick_rate: float = 0.03 # multiplier: speed * this = ticks/sec
@export var tick_timing_randomness: float = 0.02 # max random seconds added to each tick interval

var all_pieces: Node3D
var tick_timer: float = 0.0
var startup_complete: bool = false

func _ready() -> void:
	all_pieces = owner.find_child("AllPieces", true, false)
	wheel_startup()

func wheel_startup():
	startup_complete = false
	WheelGlobals.rotation_speed = 600
	await get_tree().create_timer(0.2).timeout
	WheelGlobals.rotation_speed = WheelGlobals.preview_rotation_speed
	startup_complete = true

func _process(delta: float) -> void:
	if all_pieces:
		all_pieces.rotation.z += deg_to_rad(WheelGlobals.rotation_speed) * delta

	if not startup_complete:
		return

	var speed := absf(WheelGlobals.rotation_speed)

	if speed < min_speed_threshold:
		tick_timer = 0.0
		return

	var tick_rate := minf(speed * speed_to_tick_rate, max_tick_rate)
	var tick_interval := 1.0 / tick_rate

	tick_timer += delta
	if tick_timer >= tick_interval + randf_range(0.0, tick_timing_randomness):
		tick_timer = fmod(tick_timer, tick_interval)
		AudioGlobals.play_random_wheel_tick_sfx()
