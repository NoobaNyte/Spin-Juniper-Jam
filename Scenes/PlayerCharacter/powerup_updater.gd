extends Node

var player: CharacterBody3D

func _ready() -> void:
	# Assuming 'owner' is the Player CharacterBody3D
	player = owner
