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


# vars
var tickets: int = 0:
    set(value):
        tickets = value
        update_tickets.emit(tickets)

var starting_tickets: int = 10000 # set higher to start with more for dev testing

var hp_powerup_amount: int = 0
var speed_powerup_amount: int = 0
var jump_powerup_amount: int = 0
var invincibility_powerup_amount: int = 0


func _init() -> void:
    tickets = starting_tickets