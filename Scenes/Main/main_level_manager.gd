extends Node3D

func _ready() -> void:
	PlayerGlobals.set_in_menu_stats.emit()