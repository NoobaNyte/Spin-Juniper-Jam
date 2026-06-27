extends Area3D

var respawning: bool = false
var playing: bool = false

func _ready() -> void:
	PlayerGlobals.start_game.connect(on_start_game)
	PlayerGlobals.after_game_reset.connect(after_game_reset)

func on_start_game():
	playing = true

func after_game_reset():
	playing = false

func _on_body_entered(body: Node3D) -> void:
	if respawning or playing:
		return
	if body.is_in_group("Player"):
		await get_tree().create_timer(0.25).timeout
		var shop_spawnpoint: Marker3D = owner.find_child("ShopSpawnPoint", true, false)
		var player: CharacterBody3D = owner.find_child("PlayerCharacter", true, false)
		
		PlayerGlobals.disappear_player.emit()
		PlayerGlobals.disable_movement = true
		await get_tree().create_timer(0.5).timeout
		player.global_position = shop_spawnpoint.global_position
		player.global_rotation = shop_spawnpoint.global_rotation

		await get_tree().create_timer(0.2).timeout
		PlayerGlobals.reveal_player.emit()
		PlayerGlobals.disable_movement = false

		respawning = false
