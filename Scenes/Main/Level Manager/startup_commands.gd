class_name LevelStartupCommands
extends Resource

@export var start_of_level_wheel_speed: float = 20
@export var min_piece_angle: int = 50
@export var max_piece_angle: int = 60
@export var min_gap_angle_size: int = 10
@export var max_gap_angle_size: int = 20

@export_group("progress bar and prizes")
@export var ticket_points: Array[ProgressBarTicketPoint] # any subclass can go here