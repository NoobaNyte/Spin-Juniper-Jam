extends Node

## signals
@warning_ignore("unused_signal")
signal set_in_menu_stats

@warning_ignore("unused_signal")
signal set_in_game_stats

@warning_ignore("unused_signal")
signal show_prize_prices

@warning_ignore("unused_signal")
signal hide_prize_prices

@warning_ignore("unused_signal")
signal update_tickets

@warning_ignore("unused_signal")
signal update_selected_level


# vars
var tickets: int = 0:
    set(value):
        tickets = value
        update_tickets.emit(tickets)
var starting_tickets: int = 10000 # set higher to start with more for dev testing

var total_levels: int = 5
var selected_level: int = 1: # this number is the default selected level
    set(value):
        selected_level = value
        update_selected_level.emit()


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