extends Node3D

@export var play_area_hologram: Node3D
@export var play_area: Area3D

var current_tween: Tween
var progress_tween: Tween
var original_progress_scale: Vector3

var input_prompt_ui

func _ready() -> void:
	PlayerGlobals.set_in_menu_stats.emit()
	PlayerGlobals.reset_game.connect(reset_game)
	input_prompt_ui = UI.get_node("InputPrompt")

	# --- HOLOGRAM WALL SETUP ---
	var play_area_walls = play_area_hologram.get_children()
	for wall in play_area_walls:
		if wall is MeshInstance3D:
			var mat = wall.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				var unique_mat = mat.duplicate()
				unique_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				
				# BULLETPROOF COLOR FIX: Pull it out, change it, put it back!
				var start_color = unique_mat.albedo_color
				start_color.a = 0.0
				unique_mat.albedo_color = start_color
				
				# Apply the invisible material to the wall
				wall.set_surface_override_material(0, unique_mat)

				# Force the node to hide
				wall.hide()

func _on_play_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		fade_all_play_area_hologram_walls(false) # false = fade in
		input_prompt_ui.change_input_text_to("PLAY")
		input_prompt_ui.fade_in(input_prompt_ui)

func _on_play_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		fade_all_play_area_hologram_walls(true) # true = fade out
		input_prompt_ui.fade_out(input_prompt_ui)

func fade_all_play_area_hologram_walls(is_fade_out: bool = false, fade_time: float = 0.4) -> void:
	# MATH FIX: Godot alpha uses 0.0 to 1.0!
	var fade_to: float = 0.0 if is_fade_out else 1.0

	var play_area_walls = play_area_hologram.get_children()
	
	# TWEEN FIGHTING FIX: If a fade is already happening, stop it and start the new one
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween().set_parallel(true)
	
	for wall in play_area_walls:
		if wall is MeshInstance3D:
			# VISIBILITY FIX: If we are fading IN, we must unhide the mesh before the animation starts!
			if not is_fade_out:
				wall.show()
			
			var mat = wall.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				current_tween.tween_property(mat, "albedo_color:a", fade_to, fade_time)
				
	await current_tween.finished
	
	# VISIBILITY FIX: ONLY hide the meshes if this was a fade OUT
	if is_fade_out:
		for wall in play_area_walls:
			if wall is MeshInstance3D:
				wall.hide()

func _input(event: InputEvent) -> void:
	if PlayerGlobals.disable_interact:
		return
	if event.is_action_pressed("Interact"):
		var bodies = play_area.get_overlapping_bodies()
		
		for body in bodies:
			if body.is_in_group("Player"):
				start_game()

func start_game() -> void:
	PlayerGlobals.disable_interact = true
	print("Starting Game!")
	
	# play sfx and confirm animations
	UI.get_node("InputPrompt").fade_out(UI.get_node("InputPrompt"))
	#await get_tree().create_timer(0.5).timeout

	# poof out the player
	PlayerGlobals.disappear_player.emit()
	PlayerGlobals.disable_movement = true
	await get_tree().create_timer(0.5).timeout # wait for poof to be done

	AudioGlobals.fade_out_shop_music.emit(8)
	PlayerGlobals.start_game.emit()

	# detach camera from player and toggle the gameplay cam
	$LevelPivot/MainCamera.detached_from_player = true
	$LevelPivot/MainCamera.toggle_playing_camera(true)
	await get_tree().create_timer(2.5).timeout # wait for cam anim to be done before rotating everything

	# rotate everything 90 degrees so gravity is correct
	$LevelPivot.rotation.x = deg_to_rad(89.9) ## CRITICAL - must be 89.9 not 90 because the wheel piece spawner breaks at 90
	var start_game_spawnpoint: Marker3D = find_child("StartGameSpawnPoint", true, false)
	var player: CharacterBody3D = find_child("PlayerCharacter", true, false)
	player.global_position = start_game_spawnpoint.global_position

	PlayerGlobals.disable_movement = false
	PlayerGlobals.reveal_player.emit()
	PlayerGlobals.set_in_game_stats.emit()
	AudioGlobals.play_level_music.emit()

	await get_tree().create_timer(0.8).timeout # wait for player to check out scene then show progress bar
	ProgressBarGlobals.start_progress_bar.emit()

func reset_game():
	$LevelPivot.rotation.x = deg_to_rad(0)

	# re-attach camera from player and toggle the gameplay cam
	var shop_spawnpoint: Marker3D = find_child("ShopSpawnPoint", true, false)
	var player: CharacterBody3D = find_child("PlayerCharacter", true, false)
	player.global_position = shop_spawnpoint.global_position

	$LevelPivot/MainCamera.detached_from_player = false
	$LevelPivot/MainCamera.toggle_playing_camera(false)
	await WheelGlobals.speed_transition(WheelGlobals.preview_rotation_speed, 1)
	AudioGlobals.play_shop_music.emit()

	await get_tree().create_timer(0.5).timeout # wait for cam anim to be done before uhhiding player
	PlayerGlobals.lost_level = false
	PlayerGlobals.set_in_menu_stats.emit()
	PlayerGlobals.fell = false
	PlayerGlobals.reveal_player.emit()
	PlayerGlobals.disable_movement = false
	WheelGlobals.rotation_speed = WheelGlobals.preview_rotation_speed
	PlayerGlobals.disable_interact = false
	PlayerGlobals.game_ended = false
