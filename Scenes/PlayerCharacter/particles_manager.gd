extends Node

@export var particles: GPUParticles3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	particles.emitting = false
	particles.one_shot = true
