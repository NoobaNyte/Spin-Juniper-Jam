extends Node3D

@export var play_area_hologram: Node3D

@export_group("Progress Bar Settings")
@export var play_area_progress_bar: Node3D
@export var fill_delay: float = 0.5 # How long to wait before showing/filling the bar
@export var fill_time: float = 3
@export var empty_time: float = 0.3 # how fast the progress bar takes to go back to 0 scale

var current_tween: Tween
var progress_tween: Tween
var original_progress_scale: Vector3

func _ready() -> void:
	PlayerGlobals.set_in_menu_stats.emit()

	# --- PROGRESS BAR SETUP ---
	if play_area_progress_bar:
		original_progress_scale = Vector3.ONE
		play_area_progress_bar.scale = Vector3(0.001, original_progress_scale.y, original_progress_scale.z)
		play_area_progress_bar.hide()
	
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
		print("fading in")
		fade_all_play_area_hologram_walls(false) # false = fade in
		start_progress_bar()

func _on_play_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("fading out")
		fade_all_play_area_hologram_walls(true) # true = fade out
		cancel_progress_bar()

func fade_all_play_area_hologram_walls(is_fade_out: bool = false, fade_time: float = 0.5) -> void:
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


func start_progress_bar() -> void:
	if not play_area_progress_bar: return

	# Kill the empty animation if they step back in quickly
	if progress_tween and progress_tween.is_valid():
		progress_tween.kill()

	progress_tween = create_tween()

	# 1. Wait for the spam-proof delay BEFORE showing or scaling anything!
	if fill_delay > 0.0:
		progress_tween.tween_interval(fill_delay)

	# 2. Tell the tween to unhide the bar ONLY after the delay finishes
	progress_tween.tween_callback(play_area_progress_bar.show)

	# 3. Animate the scale
	progress_tween.tween_property(play_area_progress_bar, "scale:x", original_progress_scale.x, fill_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Connect the finish line to a function so you can trigger the actual purchase/interaction!
	progress_tween.finished.connect(_on_progress_completed)

func cancel_progress_bar() -> void:
	if not play_area_progress_bar: return

	if progress_tween and progress_tween.is_valid():
		progress_tween.kill()

	progress_tween = create_tween()
	
	# TRANS_SINE empties it out quickly and cleanly
	progress_tween.tween_property(play_area_progress_bar, "scale:x", 0.001, empty_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	await progress_tween.finished
	play_area_progress_bar.hide()

func _on_progress_completed() -> void:
	# THE BAR IS FULL! DO YOUR STUFF HERE!
	print("Interaction confirmed! The bar filled entirely.")
