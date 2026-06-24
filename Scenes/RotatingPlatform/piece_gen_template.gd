extends Node3D

var angle_size: int
var last_rotation: float
var total_degrees_rotated: float = 0.0
var tracking_enabled: bool = true

func _ready() -> void:
	#await get_tree().process_frame # wait one frame so reparent/transform settles
	last_rotation = global_rotation.z
	print_info()

func print_info():
	print("starting_rotation: ", rad_to_deg(last_rotation))
	print("angle_size (degrees to rotate): ", angle_size)

func _process(delta: float) -> void:
	if not tracking_enabled:
		return

	# how much did we rotate THIS frame only
	var delta_rotation = global_rotation.z - last_rotation
	last_rotation = global_rotation.z
	total_degrees_rotated += rad_to_deg(delta_rotation)

	if total_degrees_rotated >= angle_size:
		signal_spawn_new_piece()

func signal_spawn_new_piece():
	var overshoot = total_degrees_rotated - angle_size
	WheelGlobals.spawn_new_wheel_piece.emit(overshoot)
	print("rotated: ", total_degrees_rotated, " now spawning new piece!")
	tracking_enabled = false
