extends Node


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
	WheelGlobals.speed_transition(800, 3)
	await wait(1.5)
	WheelGlobals.speed_transition(WheelGlobals.start_of_level_wheel_speed, 0.5)
	

func level_1():
	WheelGlobals.start_of_level_wheel_speed = 20
	WheelGlobals.min_piece_angle_size = 50
	WheelGlobals.max_piece_angle_size = 60
	await wait(1)

func level_2():
	pass

func level_3():
	pass

func level_4():
	pass

func level_5():
	pass
