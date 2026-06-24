extends Node

@export var rotation_speed: float = 55.0

var all_pieces: Node3D

func _ready() -> void:
    all_pieces = owner.find_child("AllPieces", true, false)

func _process(delta: float) -> void:
    if all_pieces:
        all_pieces.rotation.z += deg_to_rad(rotation_speed) * delta