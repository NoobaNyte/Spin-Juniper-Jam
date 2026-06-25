extends Node

var grace_period_time: float = 3 # the time that you garunteed have no obstacles after the prep level time

func _ready() -> void:
	PlayerGlobals.start_game.connect(start_game)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func start_game() -> void:
	# make sure there are no walls or gaps so you don't get spawn killed
	WheelGlobals.wall_gen_chance = 0
	WheelGlobals.empty_piece_chance = 0

	# set to default gap angle size
	WheelGlobals.min_gap_angle_size = 10
	WheelGlobals.max_gap_angle_size = 20

	match PlayerGlobals.selected_level:
		1: level_1()
		2: level_2()
		3: level_3()
		4: level_4()
		5: level_5()
			
	
func prep_wheel():
	await wait(0.25) # wait for camera to start panning slightly to ease with panning
	await WheelGlobals.speed_transition(800, 1)
	#await wait(0.5)
	await WheelGlobals.speed_transition(WheelGlobals.start_of_level_wheel_speed, 0.5)
	await wait(grace_period_time)
	
func level_1():
	WheelGlobals.start_of_level_wheel_speed = 22
	WheelGlobals.min_piece_angle_size = 70
	WheelGlobals.max_piece_angle_size = 80

	await prep_wheel()
	WheelGlobals.wall_gen_chance = 100

	await wait(5)
	emit_win()
	await WheelGlobals.speed_transition(50, 30)

func level_2():
	WheelGlobals.start_of_level_wheel_speed = 20
	WheelGlobals.min_piece_angle_size = 50
	WheelGlobals.max_piece_angle_size = 60
	WheelGlobals.min_gap_angle_size = 10
	WheelGlobals.max_gap_angle_size = 20
	
	await prep_wheel()
	WheelGlobals.wall_gen_chance = 100

func level_3():
	pass

func level_4():
	pass

func level_5():
	pass

func emit_win():
	PlayerGlobals.won_level = true
	PlayerGlobals.game_over.emit()
