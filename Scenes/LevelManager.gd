extends Node

# ── Level Manager ──────────────────────────────────────────────────────────────
# Attach to any Node in the scene. Assign the platform spawner and define
# levels below. Call next_level() to advance, or set current_level directly.

@export var platform: Node3D = null
@export var start_on_ready: bool = true

var Startup = true
# ── Level Data ─────────────────────────────────────────────────────────────────
class Level:
	# Speed: platform accelerates from speed_min to speed_max over speed_ramp_time
	var speed_min: float = 20.0
	var speed_max: float = 60.0
	var speed_ramp_time: float = 30.0  # seconds to go from min to max

	# Section angles
	var min_section_angle: float = 20.0
	var max_section_angle: float = 90.0

	# Holes
	var hole_chance: float = 0.0
	var hole_radius_min: float = 1.0
	var hole_radius_max: float = 3.0
	var hole_distance_min: float = 3.0
	var hole_distance_max: float = 10.0

	# Colors
	var section_colors: Array[Color] = [Color.WHITE]
	var sequential_colors: bool = false

	# Walls
	var wall_meshes: Array[Mesh] = []
	var wall_on_trailing_edge: bool = false
	var wall_on_leading_edge: bool = true
	var wall_height: float = 1.5

	func _init(
		p_speed_min: float = 20.0,
		p_speed_max: float = 60.0,
		p_speed_ramp_time: float = 30.0,
		p_min_section_angle: float = 20.0,
		p_max_section_angle: float = 90.0,
		p_hole_chance: float = 0.0,
		p_hole_radius_min: float = 1.0,
		p_hole_radius_max: float = 3.0,
		p_hole_distance_min: float = 3.0,
		p_hole_distance_max: float = 10.0,
		p_section_colors: Array[Color] = [Color.WHITE],
		p_sequential_colors: bool = false,
		p_wall_on_trailing_edge: bool = false,
		p_wall_on_leading_edge: bool = true,
		p_wall_height: float = 1.5
	) -> void:
		speed_min            = p_speed_min
		speed_max            = p_speed_max
		speed_ramp_time      = p_speed_ramp_time
		min_section_angle    = p_min_section_angle
		max_section_angle    = p_max_section_angle
		hole_chance          = p_hole_chance
		hole_radius_min      = p_hole_radius_min
		hole_radius_max      = p_hole_radius_max
		hole_distance_min    = p_hole_distance_min
		hole_distance_max    = p_hole_distance_max
		section_colors       = p_section_colors
		sequential_colors    = p_sequential_colors
		wall_on_trailing_edge = p_wall_on_trailing_edge
		wall_on_leading_edge  = p_wall_on_leading_edge
		wall_height          = p_wall_height


# ── Define your levels here ────────────────────────────────────────────────────
# Edit or extend this array to add more levels.
var levels: Array = []

var current_level: int = 0
var _level_time: float = 0.0   # time spent in the current level


func _ready() -> void:
	# ── Build levels ───────────────────────────────────────────────────────────
	# Each Level() call takes positional args matching the _init signature above.
	# Easiest to construct them with named assignment after init instead:

	var l0 := Level.new()
	l0.speed_min         = 20.0
	l0.speed_max         = 45.0
	l0.speed_ramp_time   = 40.0
	l0.min_section_angle = 30.0
	l0.max_section_angle = 90.0
	l0.wall_height       = 0.0
	l0.wall_on_leading_edge = false
	l0.wall_on_trailing_edge = false
	l0.hole_chance       = 0.0
	l0.section_colors    = [Color(0.2, 0.6, 1.0), Color(0.014, 0.153, 0.392, 1.0)]
	l0.sequential_colors = true
	levels.append(l0)

	var l1 := Level.new()
	l1.speed_min         = 25.0
	l1.speed_max         = 55.0
	l1.speed_ramp_time   = 40.0
	l1.min_section_angle = 25.0
	l1.max_section_angle = 70.0
	l1.hole_chance       = 0.3
	l1.hole_radius_min   = 1.0
	l1.hole_radius_max   = 2.5
	l1.hole_distance_min = 5.0
	l1.hole_distance_max = 12.0
	l1.section_colors    = [Color(0.944, 0.722, 0.0, 1.0), Color(0.251, 0.533, 0.0, 1.0)]
	l1.sequential_colors = true
	levels.append(l1)

	var l2 := Level.new()
	l2.speed_min         = 40.0
	l2.speed_max         = 90.0
	l2.speed_ramp_time   = 45.0
	l2.min_section_angle = 20.0
	l2.max_section_angle = 75.0
	l2.hole_chance       = 0.6
	l2.hole_radius_min   = 1.5
	l2.hole_radius_max   = 3.5
	l2.hole_distance_min = 6.0
	l2.hole_distance_max = 13.0
	l2.section_colors    = [Color(0.966, 0.316, 0.645, 1.0), Color(0.591, 0.544, 0.999, 1.0), Color(0.259, 0.802, 0.946, 1.0), Color(0.906, 0.878, 0.605, 1.0)]
	l2.sequential_colors = false
	l2.wall_on_leading_edge  = true
	l2.wall_on_trailing_edge = false
	l2.wall_height           = 1.5
	levels.append(l2)
	
	
	var l3 := Level.new()
	l3.speed_min         = 50.0
	l3.speed_max         = 110.0
	l3.speed_ramp_time   = 45.0
	l3.min_section_angle = 20.0
	l3.max_section_angle = 75.0
	l3.hole_chance       = 0.6
	l3.hole_radius_min   = 1.5
	l3.hole_radius_max   = 3.5
	l3.hole_distance_min = 6.0
	l3.hole_distance_max = 13.0
	l3.section_colors    = [Color(0.617, 0.678, 0.856, 1.0), Color(0.0, 0.493, 0.608, 1.0), Color(0.751, 0.872, 0.914, 1.0), Color(0.061, 0.211, 0.231, 1.0)]
	l3.sequential_colors = false
	l3.wall_on_leading_edge  = true
	l3.wall_on_trailing_edge = false
	l3.wall_height           = 1.5

	levels.append(l3);
	
	var l4 := Level.new()
	l4.speed_min         = 60.0
	l4.speed_max         = 130.0
	l4.speed_ramp_time   = 35.0
	l4.min_section_angle = 15.0
	l4.max_section_angle = 60.0
	l4.hole_chance       = 0.75
	l4.hole_radius_min   = 1.5
	l4.hole_radius_max   = 3.5
	l4.hole_distance_min = 6
	l4.hole_distance_max = 13.0
	l4.section_colors    = [Color(0.073, 0.073, 0.073, 1.0), Color(0.642, 0.0, 0.112, 1.0)]
	l4.sequential_colors = true
	l4.wall_on_leading_edge  = true
	l4.wall_on_trailing_edge = false
	l4.wall_height           = 1.5

	levels.append(l4);
	

	if start_on_ready:
		current_level = -1
		apply_level(current_level)
		await get_tree().create_timer(2.5).timeout
		current_level = 0
		Startup = false
		apply_level(current_level)
		


func _physics_process(delta: float) -> void:
	if platform == null or levels.is_empty():
		return

	var lvl: Level = levels[current_level]
	_level_time += delta

	# Ramp speed smoothly from min to max over speed_ramp_time
	var t: float = clamp(_level_time / lvl.speed_ramp_time, 0.0, 1.0)
	platform.rotation_speed_deg = lerpf(lvl.speed_min, lvl.speed_max, t)


# ── Public API ─────────────────────────────────────────────────────────────────

func next_level() -> void:
	if current_level + 1 < levels.size():
		current_level += 1
		apply_level(current_level)
	else:
		push_warning("LevelManager: already on last level (%d)" % current_level)

func prev_level() -> void:
	if current_level - 1 < 0:
		current_level -=1
		apply_level(current_level)
	else:
		push_warning("LevelManager: already on first level (%d)" % current_level)

func go_to_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("LevelManager: level index %d out of range" % index)
		return
	current_level = index
	apply_level(current_level)


func apply_level(index: int) -> void:
	if platform == null:
		push_error("LevelManager: platform is not assigned")
		return
		
		
	if index < 0 or index >= levels.size():
		if Startup:
			var l0 := Level.new()

			l0.speed_min         = 300.0
			l0.speed_max         = 300.0
			l0.speed_ramp_time   = 40.0
			l0.min_section_angle = 30.0
			l0.max_section_angle = 90.0
			l0.wall_height       = 0.0
			l0.wall_on_leading_edge = false
			l0.wall_on_trailing_edge = false
			l0.hole_chance       = 0.0
			l0.section_colors    = [Color(0.2, 0.6, 1.0), Color(0.014, 0.153, 0.392, 1.0)]
			l0.sequential_colors = true
			levels.append(l0)
			
			platform.rotation_speed_deg   = l0.speed_min
			platform.min_section_angle    = l0.min_section_angle
			platform.max_section_angle    = l0.max_section_angle
			platform.hole_chance          = l0.hole_chance
			platform.hole_radius_min      = l0.hole_radius_min
			platform.hole_radius_max      = l0.hole_radius_max
			platform.hole_distance_min    = l0.hole_distance_min
			platform.hole_distance_max    = l0.hole_distance_max
			platform.section_colors       = l0.section_colors
			platform.sequential_colors    = l0.sequential_colors
			platform.wall_on_trailing_edge = l0.wall_on_trailing_edge
			platform.wall_on_leading_edge  = l0.wall_on_leading_edge
			platform.wall_height          = l0.wall_height
			return
		push_error("LevelManager: level index %d out of range" % index)
		return

	_level_time = 0.0
	var lvl: Level = levels[index]

	platform.rotation_speed_deg   = lvl.speed_min
	platform.min_section_angle    = lvl.min_section_angle
	platform.max_section_angle    = lvl.max_section_angle
	platform.hole_chance          = lvl.hole_chance
	platform.hole_radius_min      = lvl.hole_radius_min
	platform.hole_radius_max      = lvl.hole_radius_max
	platform.hole_distance_min    = lvl.hole_distance_min
	platform.hole_distance_max    = lvl.hole_distance_max
	platform.section_colors       = lvl.section_colors
	platform.sequential_colors    = lvl.sequential_colors
	platform.wall_on_trailing_edge = lvl.wall_on_trailing_edge
	platform.wall_on_leading_edge  = lvl.wall_on_leading_edge
	platform.wall_height          = lvl.wall_height
