extends Node

var prep_level_time: float = 1.75 # the time that every level will wait before starting their main logic, the time it takes the wheel to prep

func _ready() -> void:
	PlayerGlobals.start_game.connect(start_game)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func start_game() -> void:
	await prep_wheel()

	match PlayerGlobals.selected_level:
		1: level_1()
		2: level_2()
		3: level_3()
		4: level_4()
		5: level_5()
			
	
func prep_wheel():
	await wait(0.25) # wait for camera to start panning slightly to ease with panning
	await WheelGlobals.speed_transition(800, 1)
	await wait(0.5)
	WheelGlobals.speed_transition(WheelGlobals.start_of_level_wheel_speed, 0.5)
	

func level_1():
	WheelGlobals.start_of_level_wheel_speed = 20
	WheelGlobals.min_piece_angle_size = 50
	WheelGlobals.max_piece_angle_size = 60
	WheelGlobals.wall_gen_chance = 0
	
	await wait(prep_level_time)

func level_2():
	pass

func level_3():
	pass

func level_4():
	pass

func level_5():
	pass
