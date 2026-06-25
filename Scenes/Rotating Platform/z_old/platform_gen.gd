extends Node3D

@export_category("Wheel Physics")
@export var speed_deg_per_sec: float = 45.0
@export var spin_axis: Vector3 = Vector3(0, 1, 0)

@export_category("Endless Treadmill")
@export_range(10.0, 360.0) var visible_arc_degrees: float = 360
@export_range(0.0, 360.0) var treadmill_start_angle: float = 0

@export_category("Wheel Dimensions")
@export var wheel_radius: float = 15.0
@export var wheel_inner_radius: float = 0.0
@export var wheel_thickness: float = 1.0

@export_category("Segment Generation")
@export_range(1.0, 180.0) var min_piece_angle: float = 10.0
@export_range(1.0, 180.0) var max_piece_angle: float = 30.0

@export_category("Visuals")
@export var piece_colors: Array[Color] = [Color.WHITE, Color.DARK_GRAY]
@export var use_random_piece_colors: bool = false
@export var wall_meshes: Array[Mesh] = []

# --- Internal Tracking ---
var _gap_offset: Node3D
var _spinner: Node3D
var _remote_transform: RemoteTransform3D
var _wheel_body: AnimatableBody3D

var _segments: Array[Dictionary] = []
var _accumulated_rotation: float = 0.0
var _next_spawn_angle: float = 0.0
var _color_index: int = 0

func _ready() -> void:
	_gap_offset = Node3D.new()
	_gap_offset.rotation_degrees.y = treadmill_start_angle
	add_child(_gap_offset)

	_spinner = Node3D.new()
	_gap_offset.add_child(_spinner)

	_remote_transform = RemoteTransform3D.new()
	_spinner.add_child(_remote_transform)

	_wheel_body = AnimatableBody3D.new()
	_wheel_body.top_level = true
	add_child(_wheel_body)

	_remote_transform.remote_path = _remote_transform.get_path_to(_wheel_body)

	_next_spawn_angle = treadmill_start_angle - _accumulated_rotation
	_manage_endless_segments()

func _physics_process(delta: float) -> void:
	_accumulated_rotation += speed_deg_per_sec * delta
	_spinner.rotation_degrees = spin_axis * _accumulated_rotation

	_normalize_tracking_angles()
	_manage_endless_segments()

func _manage_endless_segments() -> void:
	var visible_start_world = treadmill_start_angle
	var visible_end_world = visible_start_world + visible_arc_degrees
	var visible_start_local = visible_start_world - _accumulated_rotation
	var visible_end_local = visible_end_world - _accumulated_rotation

	while _segments.size() > 0 and _segments[0]["end_angle"] + _accumulated_rotation < visible_start_world:
		var old_segment = _segments.pop_front()
		for node in old_segment["nodes"]:
			if is_instance_valid(node):
				node.queue_free()

	if _next_spawn_angle < visible_start_local:
		_next_spawn_angle = visible_start_local

	while _next_spawn_angle < visible_end_local:
		_spawn_piece()

func _normalize_tracking_angles() -> void:
	if _accumulated_rotation < 360.0:
		return

	var offset = floor(_accumulated_rotation / 360.0) * 360.0
	_accumulated_rotation -= offset
	_next_spawn_angle -= offset

	for segment in _segments:
		segment["end_angle"] -= offset

func _spawn_piece() -> void:
	var piece_angle = randf_range(min_piece_angle, max_piece_angle)
	var start_local = _next_spawn_angle
	var end_local = start_local + piece_angle
	var nodes: Array[Node] = []

	var mesh = _create_wedge_mesh(start_local, end_local)
	var piece = MeshInstance3D.new()
	piece.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = _choose_piece_color()
	piece.material_override = material

	var piece_collision = CollisionShape3D.new()
	piece_collision.shape = mesh.create_convex_shape(true, true)

	_wheel_body.add_child(piece); nodes.append(piece)
	_wheel_body.add_child(piece_collision); nodes.append(piece_collision)

	if wall_meshes.size() > 0:
		var wall_mesh = wall_meshes[randi() % wall_meshes.size()]
		var wall = MeshInstance3D.new()
		wall.mesh = wall_mesh
		var edge_rad = deg_to_rad(start_local)
		var edge_radius = (wheel_radius + wheel_inner_radius) * 0.5
		wall.position = Vector3(cos(edge_rad) * edge_radius, wheel_thickness * 0.5, sin(edge_rad) * edge_radius)
		wall.look_at(wall.position + Vector3(cos(edge_rad), 0, sin(edge_rad)), Vector3.UP)
		_wheel_body.add_child(wall); nodes.append(wall)

		var wall_collision = CollisionShape3D.new()
		wall_collision.shape = wall_mesh.create_convex_shape(true, true)
		_wheel_body.add_child(wall_collision); nodes.append(wall_collision)

	_segments.append({"end_angle": end_local, "nodes": nodes})
	_next_spawn_angle = end_local

func _choose_piece_color() -> Color:
	if piece_colors.size() == 0:
		return Color.WHITE

	if use_random_piece_colors:
		return piece_colors[randi() % piece_colors.size()]

	var color = piece_colors[_color_index % piece_colors.size()]
	_color_index += 1
	return color

func _create_wedge_mesh(start: float, end: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var steps = max(2, int((end - start) / 5.0))
	var step_deg = (end - start) / steps

	for i in steps:
		var a1 = deg_to_rad(start + i * step_deg)
		var a2 = deg_to_rad(start + (i + 1) * step_deg)

		var p1 = Vector3(cos(a1) * wheel_radius, 0, sin(a1) * wheel_radius)
		var p2 = Vector3(cos(a2) * wheel_radius, 0, sin(a2) * wheel_radius)
		var p3 = Vector3(cos(a1) * wheel_inner_radius, 0, sin(a1) * wheel_inner_radius)
		var p4 = Vector3(cos(a2) * wheel_inner_radius, 0, sin(a2) * wheel_inner_radius)
		var t = Vector3(0, wheel_thickness, 0)

		_add_quad(st, p1 + t, p2 + t, p4 + t, p3 + t)
		_add_quad(st, p3, p4, p2, p1)
		_add_quad(st, p1, p2, p2 + t, p1 + t)
		_add_quad(st, p4, p3, p3 + t, p4 + t)

		if i == 0:
			_add_quad(st, p1 + t, p3 + t, p3, p1)
		if i == steps - 1:
			_add_quad(st, p4 + t, p2 + t, p2, p4)

	st.generate_normals()
	return st.commit()

func _add_quad(st: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> void:
	st.add_vertex(p1)
	st.add_vertex(p2)
	st.add_vertex(p3)
	st.add_vertex(p1)
	st.add_vertex(p3)
	st.add_vertex(p4)
