extends Node


func _ready() -> void:
	PlayerGlobals.start_game.connect(start_game)


func start_game() -> void:
	match PlayerGlobals.selected_level:
		1:
			level_1()
		2:
			level_2()
		3:
			level_3()
		4:
			level_4()
		5:
			level_5()

func level_1():
	WheelGlobals.speed_transition(10, 1)

func level_2():
	pass

func level_3():
	pass

func level_4():
	pass

func level_5():
	pass
