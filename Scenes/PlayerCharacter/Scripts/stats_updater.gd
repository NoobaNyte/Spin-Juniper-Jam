extends Node

var player_character: CharacterBody3D

@export_group("In Menu Player Stats")
@export var menu_scale: float = 1.5
@export var menu_move_speed: float = 8
@export var menu_jump_velocity: float = 12
@export var menu_running_animation_speed: float = 2.75
@export var menu_jump_animation_speed: float = 1.15
@export var menu_gravity_scale: float = 3.5

@export_group("In Game Player Stats")
@export var game_scale: float = 1
@export var game_move_speed: float = 6
@export var game_jump_velocity: float = 8
@export var game_running_animation_speed: float = 2.0
@export var game_jump_animation_speed: float = 1.15
@export var game_gravity_scale: float = 2.5

func _ready() -> void:
	player_character = owner
	PlayerGlobals.set_in_menu_stats.connect(set_in_menu_stats)
	PlayerGlobals.set_in_game_stats.connect(set_in_game_stats)


func set_in_menu_stats():
	if player_character:
		player_character.scale = Vector3(menu_scale, menu_scale, menu_scale)
		player_character.move_speed = menu_move_speed
		player_character.jump_velocity = menu_jump_velocity
		player_character.speed_running = menu_running_animation_speed
		player_character.speed_jump = menu_jump_animation_speed
		player_character.gravity_scale = menu_gravity_scale

	else:
		printerr("player character not found in stats_updater.gd! go to stats_updater.gd to update it's assignment in 'ready()'")

func set_in_game_stats():
	if player_character:
		player_character.scale = Vector3(game_scale, game_scale, game_scale)
		player_character.move_speed = game_move_speed
		player_character.jump_velocity = game_jump_velocity
		player_character.speed_running = game_running_animation_speed
		player_character.speed_jump = game_jump_animation_speed
		player_character.gravity_scale = game_gravity_scale

	else:
		printerr("player character not found in stats_updater.gd! go to stats_updater.gd to update it's assignment in 'ready()'")