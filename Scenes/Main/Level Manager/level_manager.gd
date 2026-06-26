extends Node

var grace_period_time: float = 1 # the time that you garunteed have no obstacles after the prep level time

# falling objects that can be used to spawn:
@export_category("Falling Objects")
@export var ball: PackedScene

@export_category("Configure Levels")
@export var levels: Array[LevelSequence]

func _ready() -> void:
	# when start game is signalled, start the game based on the selected level (-1 because array)
	PlayerGlobals.start_game.connect(func(): run_level(PlayerGlobals.selected_level - 1))
	assign_vars_to_global()

func assign_vars_to_global():
	for i in range(5):
		var sequence = levels[i]
		var base_level_data = sequence.base_level_data
		
		match i:
			0:
				WheelGlobals.level_1_colors = base_level_data.colors
				WheelGlobals.level_1_walls = base_level_data.walls
			1:
				WheelGlobals.level_2_colors = base_level_data.colors
				WheelGlobals.level_2_walls = base_level_data.walls
			2:
				WheelGlobals.level_3_colors = base_level_data.colors
				WheelGlobals.level_3_walls = base_level_data.walls
			3:
				WheelGlobals.level_4_colors = base_level_data.colors
				WheelGlobals.level_4_walls = base_level_data.walls
			4:
				WheelGlobals.level_5_colors = base_level_data.colors
				WheelGlobals.level_5_walls = base_level_data.walls
		

func run_level(level_index: int) -> void:
	# make sure there are no walls or gaps so you don't get spawn killed
	WheelGlobals.wall_gen_chance = 0
	WheelGlobals.empty_piece_chance = 0

	# set to default gap angle size
	WheelGlobals.min_gap_angle_size = 10
	WheelGlobals.max_gap_angle_size = 20

	# choose the correct level sequence to run
	var sequence = levels[level_index]

	# run all mandatory startup commands
	var s = sequence.startup_commands
	WheelGlobals.start_of_level_wheel_speed = s.start_of_level_wheel_speed
	WheelGlobals.min_piece_angle_size = s.min_piece_angle
	WheelGlobals.max_piece_angle_size = s.max_piece_angle
	WheelGlobals.min_gap_angle_size = s.min_gap_angle_size
	WheelGlobals.max_gap_angle_size = s.max_gap_angle_size

	for ticket_point in s.ticket_points:
		ProgressBarGlobals.add_ticket_point.emit(ticket_point.point_on_progress_bar_from_0_to_1)
	
	# tell the progress bar how long the level is
	var command_time_count: float = 0
	for cmd in sequence.commands:
		cmd.check_time()
		command_time_count += cmd.total_command_time

	ProgressBarGlobals.selected_level_length_in_seconds = command_time_count
	
	await prep_wheel() # make the wheel get prepped

	# Run level commands
	for cmd in sequence.commands:
		if PlayerGlobals.lost_level: return
		await cmd.execute(self)
	
	if not PlayerGlobals.lost_level:
		emit_win()

func prep_wheel():
	await wait(0.25) # wait for camera to start panning slightly to ease with panning
	await WheelGlobals.speed_transition(800, 1)
	#await wait(0.5)
	await WheelGlobals.speed_transition(WheelGlobals.start_of_level_wheel_speed, 0.5)
	await wait(grace_period_time)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func emit_win():
	PlayerGlobals.won_level = true
	PlayerGlobals.game_over.emit()
