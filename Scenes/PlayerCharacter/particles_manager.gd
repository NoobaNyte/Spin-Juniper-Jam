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

func spawn_particles() -> void:
	var dupe: GPUParticles3D = particles.duplicate()
	var level_pivot = owner.get_parent().find_child("LevelPivot", true, false)
	level_pivot.add_child(dupe)
	dupe.top_level = true
	dupe.global_transform = particles.global_transform
	dupe.emitting = true

	# wait for all particles to finish emitting and die
	await get_tree().create_timer(dupe.lifetime + 0.1).timeout
	dupe.queue_free()

func disappear_player():
	spawn_particles()
	await get_tree().create_timer(0.2).timeout
	player_mesh.visible = false

func reveal_player():
	spawn_particles()
	await get_tree().create_timer(0.2).timeout
	player_mesh.visible = true
