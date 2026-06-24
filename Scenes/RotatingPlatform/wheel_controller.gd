extends Node

@export_group("Wheel Colors")

@export var level_1_colors: Array[Color]
@export var level_2_colors: Array[Color]
@export var level_3_colors: Array[Color]
@export var level_4_colors: Array[Color]
@export var level_5_colors: Array[Color]

var all_pieces: Node3D

func _ready() -> void:
	all_pieces = owner.find_child("AllPieces", true, false)
	assign_colors_to_global()

func assign_colors_to_global():
	WheelGlobals.level_1_colors = level_1_colors
	WheelGlobals.level_2_colors = level_2_colors
	WheelGlobals.level_3_colors = level_3_colors
	WheelGlobals.level_4_colors = level_4_colors
	WheelGlobals.level_5_colors = level_5_colors

func _process(delta: float) -> void:
	if all_pieces:
		all_pieces.rotation.z += deg_to_rad(WheelGlobals.rotation_speed) * delta
