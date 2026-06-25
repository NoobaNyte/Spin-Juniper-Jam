extends Node

@export_group("Wheel Colors")
@export var level_1_colors: Array[Color]
@export var level_2_colors: Array[Color]
@export var level_3_colors: Array[Color]
@export var level_4_colors: Array[Color]
@export var level_5_colors: Array[Color]

@export_group("Walls")
@export var level_1_walls: Array[PackedScene]
@export var level_2_walls: Array[PackedScene]
@export var level_3_walls: Array[PackedScene]
@export var level_4_walls: Array[PackedScene]
@export var level_5_walls: Array[PackedScene]

var all_pieces: Node3D

func _ready() -> void:
	all_pieces = owner.find_child("AllPieces", true, false)
	assign_vars_to_global()
	wheel_startup()

func wheel_startup():
	WheelGlobals.rotation_speed = 600
	await get_tree().create_timer(0.2).timeout
	WheelGlobals.rotation_speed = WheelGlobals.preview_rotation_speed

func assign_vars_to_global():
	## colors
	WheelGlobals.level_1_colors = level_1_colors
	WheelGlobals.level_2_colors = level_2_colors
	WheelGlobals.level_3_colors = level_3_colors
	WheelGlobals.level_4_colors = level_4_colors
	WheelGlobals.level_5_colors = level_5_colors

	## walls
	WheelGlobals.level_1_walls = level_1_walls
	WheelGlobals.level_2_walls = level_2_walls
	WheelGlobals.level_3_walls = level_3_walls
	WheelGlobals.level_4_walls = level_4_walls
	WheelGlobals.level_5_walls = level_5_walls

func _process(delta: float) -> void:
	if all_pieces:
		all_pieces.rotation.z += deg_to_rad(WheelGlobals.rotation_speed) * delta
