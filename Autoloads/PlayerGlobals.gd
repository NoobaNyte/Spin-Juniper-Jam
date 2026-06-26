extends Node

## signals
@warning_ignore("unused_signal")
signal set_in_menu_stats

@warning_ignore("unused_signal")
signal set_in_game_stats

@warning_ignore("unused_signal")
signal disappear_player

@warning_ignore("unused_signal")
signal reveal_player

@warning_ignore("unused_signal")
signal show_prize_prices

@warning_ignore("unused_signal")
signal hide_prize_prices

@warning_ignore("unused_signal")
signal update_tickets

@warning_ignore("unused_signal")
signal update_selected_level

@warning_ignore("unused_signal")
signal start_game

@warning_ignore("unused_signal")
signal game_over

@warning_ignore("unused_signal")
signal reset_game

@warning_ignore("unused_signal")
signal trigger_fall_down

@warning_ignore("unused_signal")
signal set_player_collision_layers(layers: Array[int])

@warning_ignore("unused_signal")
signal play_i_frames_animation()


# player movement stat change signals
@warning_ignore("unused_signal")
signal set_move_speed(speed: float)
@warning_ignore("unused_signal")
signal increase_move_speed(speed: float)
@warning_ignore("unused_signal")
signal set_rotation_speed(speed: float)
@warning_ignore("unused_signal")
signal increase_rotation_speed(speed: float)
@warning_ignore("unused_signal")
signal set_acceleration(accel: float)
@warning_ignore("unused_signal")
signal increase_acceleration(accel: float)
@warning_ignore("unused_signal")
signal set_jump_velocity(vel: float)
@warning_ignore("unused_signal")
signal increase_jump_velocity(vel: float)
@warning_ignore("unused_signal")
signal set_friction(frict: float)
@warning_ignore("unused_signal")
signal increase_friction(frict: float)
# end player movement stat change signals

# vars
var disable_movement: bool = false
var disable_interact: bool = false
var won_level: bool = false
var lost_level: bool = false # used to not emit win if you've already lost (in level_manager.gd) gets set to true in game_over_manager.gd
var fell: bool = false: # if you fell to a wall (not off screen)
	set(val):
		fell = val
		if fell:
			trigger_fall_down.emit()
var game_ended: bool = false # used to make it so the player can't trigger death a second time
var invincible: bool = true: # used to do i frames animation in PlayerMovement.gd when the player has i frames
	set(val):
		invincible = val
		if invincible:
			play_i_frames_animation.emit()
var playerCurrentHealth: int = 1
var playertIFrameSeconds: float = 1

# prize behavior vars

var speedPrizeAccel: bool = false

# end prize behavior vars

var tickets: int = 0:
	set(value):
		tickets = value
		update_tickets.emit(tickets)
var starting_tickets: int = 10000 # set higher to start with more for dev testing

var total_levels: int = 5
var selected_level: int = 1: # this number is the default selected level - ALSO SETS PREVIEW STATS
	set(value):
		selected_level = value
		update_selected_level.emit()
		update_preview_wheel()
	   
					
# starting powerup amount and costs are set individually in inspector for each prize in each prize scene
var hp_powerup_amount: int = 5
var hp_powerup_cost: int = 0
var speed_powerup_amount: int = 0
var speed_powerup_cost: int = 0
var jump_powerup_amount: int = 0
var jump_powerup_cost: int = 0
var invincibility_powerup_amount: int = 5
var invincibility_powerup_cost: int = 0
var bear_powerup_amount: int = 0
var bear_powerup_cost: int = 0

func _init() -> void:
	tickets = starting_tickets

func update_preview_wheel():
	match selected_level:
		1: WheelGlobals.wall_gen_chance = 0
		2: WheelGlobals.wall_gen_chance = 50
		3: WheelGlobals.wall_gen_chance = 60
		4: WheelGlobals.wall_gen_chance = 70
		5: WheelGlobals.wall_gen_chance = 80

	match selected_level:
		1: WheelGlobals.empty_piece_chance = 0
		2: WheelGlobals.empty_piece_chance = 20
		3: WheelGlobals.empty_piece_chance = 0
		4: WheelGlobals.empty_piece_chance = 0
		5: WheelGlobals.empty_piece_chance = 0

	match selected_level:
		1:
			WheelGlobals.min_gap_angle_size = 10
			WheelGlobals.max_gap_angle_size = 20
		2:
			WheelGlobals.min_gap_angle_size = 10
			WheelGlobals.max_gap_angle_size = 20
		3:
			WheelGlobals.min_gap_angle_size = 10
			WheelGlobals.max_gap_angle_size = 20
		4:
			WheelGlobals.min_gap_angle_size = 10
			WheelGlobals.max_gap_angle_size = 20
		5:
			WheelGlobals.min_gap_angle_size = 10
			WheelGlobals.max_gap_angle_size = 20
