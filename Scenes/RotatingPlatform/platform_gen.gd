@tool
extends Node3D

@export_category("Wheel Physics")
## How fast the wheel spins in degrees per second. Can be changed via code mid-game!
@export var speed_deg_per_sec: float = 45.0
## Spin axis (Vector3.UP means it spins like a flat pie chart on the floor)
@export var spin_axis: Vector3 = Vector3(0, 1, 0)

@export_category("Endless Treadmill Settings")
## How much of the circle exists at any given time.
## Keep this under 360 (e.g., 270 or 180) to leave an invisible "gap" off-camera
## where pieces safely despawn and respawn without clipping into each other!
@export_range(90.0, 350.0) var visible_arc_degrees: float = 270.0:
	set(v): visible_arc_degrees = v; _queue_rebuild()

@export_category("Wheel Dimensions")
@export var wheel_outer_radius: float = 15.0:
	set(v): wheel_outer_radius = v; _queue_rebuild()
@export var wheel_inner_radius: float = 0.0:
	set(v): wheel_inner_radius = v; _queue_rebuild()
@export var wheel_thickness: float = 1.0:
	set(v): wheel_thickness = v; _queue_rebuild()

@export_category("Segment Generation")
@export var min_piece_angle: float = 15.0:
	set(v): min_piece_angle = v; _queue_rebuild()
@export var max_piece_angle: float = 45.0:
	set(v): max_piece_angle = v; _queue_rebuild()

@export_category("Colors")
@export var piece_colors: Array[Color] = [Color.WHITE, Color.DARK_GRAY]:
	set(v): piece_colors = v; _queue_rebuild()
@export var sequential_colors: bool = true:
	set(v): sequential_colors = v; _queue_rebuild()

@export_category("Walls & Dividers")
## Array of meshes to use as dividers between segments
@export var wall_meshes: Array[Mesh] = []:
	set(v): wall_meshes = v; _queue_rebuild()

# --- Internal Tracking ---
var _wheel_body: AnimatableBody3D
var _segments: Array[Dictionary] = []
var _accumulated_rotation: float = 0.0
var _head_angle: float = 0.0
var _color_index: int = 0
var _needs_rebuild: bool = false

func _ready() -> void:
	_rebuild_wheel()

func _process(_delta: float) -> void:
	# Handles live-updating in the Editor Viewport when you change inspector variables
	if Engine.is_editor_hint() and _needs_rebuild:
		_rebuild_wheel()
		_needs_rebuild = false

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return # Do not spin in the editor, only in the real game!
		
	if is_instance_valid(_wheel_body):
		var step = speed_deg_per_sec * delta
		_wheel_body.rotate(spin_axis.normalized(), deg_to_rad(step))
		_accumulated_rotation += step
		
		_manage_endless_segments()

# ========================================================
# CORE GENERATION & MEMORY MANAGEMENT
# ========================================================

func _queue_rebuild() -> void:
	if Engine.is_editor_hint():
		_needs_rebuild = true

func _rebuild_wheel() -> void:
	# Clean up the old physics body to prevent memory leaks in the editor
	if is_instance_valid(_wheel_body):
		_wheel_body.queue_free()
		
	_wheel_body = AnimatableBody3D.new()
	add_child(_wheel_body)
	
	_segments.clear()
	_accumulated_rotation = 0.0
	_head_angle = 0.0
	_color_index = 0
	
	_manage_endless_segments()

func _manage_endless_segments() -> void:
	# 1. DESPAWN: Delete pieces that have fully rotated past the safe "tail" line
	while _segments.size() > 0 and _segments[0]["end_angle"] < _accumulated_rotation:
		var old_segment = _segments.pop_front()
		for node in old_segment["nodes"]:
			if is_instance_valid(node):
				node.queue_free()
				
	# 2. RESPAWN: Generate new pieces at the "head" to fill the visible arc
	while _head_angle < _accumulated_rotation + visible_arc_degrees:
		_spawn_piece()

func _spawn_piece() -> void:
	var piece_angle = randf_range(min_piece_angle, max_piece_angle)
	var start_deg = _head_angle
	var end_deg = start_deg + piece_angle
	
	var spawned_nodes: Array[Node] = []
	
	# --- 1. MESH & COLOR ---
	var wedge_mesh = _create_wedge_mesh(start_deg, end_deg)
	var wedge_mi = MeshInstance3D.new()
	wedge_mi.mesh = wedge_mesh
	
	var mat = StandardMaterial3D.new()
	if piece_colors.size() > 0:
		if sequential_colors:
			mat.albedo_color = piece_colors[_color_index % piece_colors.size()]
			_color_index += 1
		else:
			mat.albedo_color = piece_colors[randi() % piece_colors.size()]
	wedge_mi.material_override = mat
	_wheel_body.add_child(wedge_mi)
	spawned_nodes.append(wedge_mi)
	
	# --- 2. COLLISION ---
	var wedge_col = CollisionShape3D.new()
	wedge_col.shape = wedge_mesh.create_convex_shape(true, true)
	_wheel_body.add_child(wedge_col)
	spawned_nodes.append(wedge_col)
	
	# --- 3. WALLS ---
	if wall_meshes.size() > 0:
		var picked_mesh = wall_meshes[randi() % wall_meshes.size()]
		var rad = deg_to_rad(start_deg)
		var mid_radius = (wheel_outer_radius + wheel_inner_radius) / 2.0
		
		var wall_mi = MeshInstance3D.new()
		wall_mi.mesh = picked_mesh
		wall_mi.position = Vector3(cos(rad) * mid_radius, wheel_thickness / 2.0, sin(rad) * mid_radius)
		
		# Align the wall so it perfectly points down the seam
		var edge_pos = wall_mi.position + Vector3(cos(rad), 0, sin(rad))
		wall_mi.transform = wall_mi.transform.looking_at(edge_pos, Vector3.UP)
		
		var wall_col = CollisionShape3D.new()
		wall_col.shape = picked_mesh.create_trimesh_shape()
		wall_col.position = wall_mi.position
		wall_col.rotation = wall_mi.rotation
		
		_wheel_body.add_child(wall_mi)
		_wheel_body.add_child(wall_col)
		spawned_nodes.append(wall_mi)
		spawned_nodes.append(wall_col)
		
	# Track the nodes so we can safely delete them later
	_segments.append({
		"end_angle": end_deg,
		"nodes": spawned_nodes
	})
	
	_head_angle = end_deg

# ========================================================
# MATH: FLAT WEDGE MESH BUILDER
# ========================================================
func _create_wedge_mesh(start_deg: float, end_deg: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var steps = max(2, int((end_deg - start_deg) / 5.0))
	var step_deg = (end_deg - start_deg) / steps
	var half_t = wheel_thickness * 0.5
	var r_out = wheel_outer_radius
	var r_in = wheel_inner_radius
	
	for i in range(steps):
		var a1 = deg_to_rad(start_deg + i * step_deg)
		var a2 = deg_to_rad(start_deg + (i + 1) * step_deg)
		var c1 = cos(a1); var s1 = sin(a1)
		var c2 = cos(a2); var s2 = sin(a2)
		
		var p_out_1_t = Vector3(c1 * r_out, half_t, s1 * r_out)
		var p_out_2_t = Vector3(c2 * r_out, half_t, s2 * r_out)
		var p_in_1_t = Vector3(c1 * r_in, half_t, s1 * r_in)
		var p_in_2_t = Vector3(c2 * r_in, half_t, s2 * r_in)
		
		var p_out_1_b = Vector3(c1 * r_out, -half_t, s1 * r_out)
		var p_out_2_b = Vector3(c2 * r_out, -half_t, s2 * r_out)
		var p_in_1_b = Vector3(c1 * r_in, -half_t, s1 * r_in)
		var p_in_2_b = Vector3(c2 * r_in, -half_t, s2 * r_in)

		_add_quad(st, p_in_1_t, p_in_2_t, p_out_2_t, p_out_1_t) # Top
		_add_quad(st, p_out_1_b, p_out_2_b, p_in_2_b, p_in_1_b) # Bottom
		_add_quad(st, p_out_1_t, p_out_2_t, p_out_2_b, p_out_1_b) # Outer
		_add_quad(st, p_in_2_t, p_in_1_t, p_in_1_b, p_in_2_b) # Inner

		if i == 0: _add_quad(st, p_in_1_t, p_out_1_t, p_out_1_b, p_in_1_b)
		if i == steps - 1: _add_quad(st, p_out_2_t, p_in_2_t, p_in_2_b, p_out_2_b)

	st.generate_normals()
	return st.commit()
	
func _add_quad(st: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3):
	st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p3)
	st.add_vertex(p1); st.add_vertex(p3); st.add_vertex(p4)