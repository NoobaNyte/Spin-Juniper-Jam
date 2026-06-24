extends Node

@export var piece_gen_template_scene: PackedScene
var all_pieces: Node3D

func _ready() -> void:
	WheelGlobals.spawn_new_wheel_piece.connect(generate_piece)
	all_pieces = owner.find_child("AllPieces", true, false)
	generate_piece(100, 110)


func generate_piece(min_angle: int, max_angle: int, overshoot: float = 0.0):
	var angle_size: int = randi_range(min_angle, max_angle)
	
	# instantiate the piece gen template scene
	var piece = piece_gen_template_scene.instantiate()
	
	# add piece as a child of the "GeneratePiece" first to make sure piece spawns at perfect angle
	add_child(piece)
	

	# tell the piece's script its angle size
	piece.angle_size = angle_size

	# give the piece the same offset that the all_pieces currently has to make sure origin is lined up
	piece.global_position = all_pieces.global_position
	piece.global_rotation.x = all_pieces.global_rotation.x
	piece.global_rotation.y = all_pieces.global_rotation.y

	
	# reparent it to the all_pieces node (that rotates everything) to give it rotation and it will retain perfect spawn angle
	piece.reparent(all_pieces)
	
	# grab the anglecut node and rotate it the desired amount
	var angle_cut: CSGCombiner3D = piece.get_node("PieceMeshGenerator/AngleCut")
	angle_cut.rotation.z += deg_to_rad(180 - angle_size)

	# pre-rotate the new piece to cover the overshoot gap
	piece.rotation.z += deg_to_rad(overshoot)

	
func _on_destroy_detection_area_area_entered(area: Area3D) -> void:
	if area.name == "DestroyDetectionArea":
		area.owner.queue_free()