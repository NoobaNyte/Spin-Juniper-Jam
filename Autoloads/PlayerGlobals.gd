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


# vars
var disable_movement: bool = false
var won_level: bool = false

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
var hp_powerup_amount: int = 0
var hp_powerup_cost: int = 10
var speed_powerup_amount: int = 0
var speed_powerup_cost: int = 0
var jump_powerup_amount: int = 0
var jump_powerup_cost: int = 0
var invincibility_powerup_amount: int = 0
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
