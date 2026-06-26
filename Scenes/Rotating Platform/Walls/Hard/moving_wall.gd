extends AnimatableBody3D

@export var move_speed: float = 0.5 # progress ratio units per second (0.0 to 1.0)

@onready var path = $Path3D

var path_follow: PathFollow3D = null
var moving_forward: bool = true

func start_moving_wall():
	# Duplicate the Path3D (which includes PathFollow3D as a child)
	var new_path: Path3D = path.duplicate()
	
	# Add the duplicated path to this node's parent (scene level)
	get_parent().add_child(new_path)
	new_path.global_transform = path.global_transform
	
	# Grab the PathFollow3D from the duplicated path
	path_follow = null
	for child in new_path.get_children():
		if child is PathFollow3D:
			path_follow = child
			break
	
	if not path_follow:
		push_error("start_moving_wall: no PathFollow3D found inside Path3D")
		return
	
	# Reparent this AnimatableBody3D into the PathFollow3D
	var saved_transform = global_transform
	get_parent().remove_child(self)
	path_follow.add_child(self)
	global_transform = saved_transform
	
	# Delete the original Path3D
	path.queue_free()
	
	set_process(true)


func _process(delta: float) -> void:
	if not path_follow:
		return
	
	if moving_forward:
		path_follow.progress_ratio += move_speed * delta
		if path_follow.progress_ratio >= 1.0:
			path_follow.progress_ratio = 1.0
			moving_forward = false
	else:
		path_follow.progress_ratio -= move_speed * delta
		if path_follow.progress_ratio <= 0.0:
			path_follow.progress_ratio = 0.0
			moving_forward = true


func _ready() -> void:
	set_process(false)