extends Node

@export var particles: GPUParticles3D

var player_character: CharacterBody3D
var player_mesh: Node3D


func _ready() -> void:
	player_character = owner
	player_mesh = player_character.find_child("Main Character Animated", true, false)
	PlayerGlobals.disappear_player.connect(disappear_player)
	PlayerGlobals.reveal_player.connect(reveal_player)

	particles.emitting = false
	particles.one_shot = true

func disappear_player():
	particles.emitting = true
	await get_tree().create_timer(0.2).timeout # wait for particles to cover player before hiding player

	player_mesh.visible = false

func reveal_player():
	particles.emitting = true
	await get_tree().create_timer(0.2).timeout # wait for poof particles to cover screen to unhide player

	player_mesh.visible = true