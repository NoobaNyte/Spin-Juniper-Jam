extends AnimatableBody3D

@export_category("Wheel Physics")
@export var speed_deg_per_sec: float = 45.0
@export var spin_axis: Vector3 = Vector3(0, 1, 0) # Local Y-Axis

@export_category("Wheel Dimensions")
@export var wheel_outer_radius: float = 15.0
@export var wheel_inner_radius: float = 0.0
@export var wheel_thickness: float = 1.0

@export_category("Segment Generation")
@export var min_piece_angle: float = 15.0
@export var max_piece_angle: float = 45.0

@export_category("Visuals")
@export var piece_colors: Array[Color] = [Color.WHITE, Color.DARK_GRAY]
@export var wall_meshes: Array[Mesh] = []

# --- Internal Tracking ---
var _spinner: Node3D
var _wheel_body: AnimatableBody3D

func _ready() -> void:
	# 1. Create the safe spinning container
	_spinner = Node3D.new()
	add_child(_spinner)
	
	# 2. Create the Physics Body and force it to sync with parent transforms
	_wheel_body = AnimatableBody3D.new()
	_wheel_body.sync_to_physics = true # CRITICAL FIX: Forces body to obey LevelPivot rotation
	_spinner.add_child(_wheel_body)
	
	_generate_full_wheel()

func _physics_process(delta: float) -> void:
	if is_instance_valid(_spinner):
		# We rotate the standard Node3D container. 
		# This bypasses the Physics Server race condition!
		var step = deg_to_rad(speed_deg_per_sec) * delta
		_spinner.rotate_object_local(spin_axis.normalized(), step)

func _generate_full_wheel() -> void:
	var current_angle: float = 0.0
	var color_index: int = 0
	
	while current_angle < 360.0:
		var piece_angle = randf_range(min_piece_angle, max_piece_angle)
		if current_angle + piece_angle > 360.0:
			piece_angle = 360.0 - current_angle
			
		var end_angle = current_angle + piece_angle
		
		var mesh = _create_wedge_mesh(current_angle, end_angle)
		var mi = MeshInstance3D.new(); mi.mesh = mesh
		
		var mat = StandardMaterial3D.new()
		if piece_colors.size() > 0:
			mat.albedo_color = piece_colors[color_index % piece_colors.size()]
			color_index += 1
		mi.material_override = mat
		
		var col = CollisionShape3D.new()
		col.shape = mesh.create_convex_shape(true, true)
		
		_wheel_body.add_child(mi)
		_wheel_body.add_child(col)
		
		if wall_meshes.size() > 0:
			var w = wall_meshes[randi() % wall_meshes.size()]
			var w_mi = MeshInstance3D.new(); w_mi.mesh = w
			var rad = deg_to_rad(current_angle)
			var mid = (wheel_outer_radius + wheel_inner_radius) / 2.0
			w_mi.position = Vector3(cos(rad) * mid, wheel_thickness / 2.0, sin(rad) * mid)
			w_mi.look_at(w_mi.position + Vector3(cos(rad), 0, sin(rad)), Vector3.UP)
			_wheel_body.add_child(w_mi)
			
		current_angle += piece_angle

func _create_wedge_mesh(start: float, end: float) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps = max(2, int((end - start) / 5.0))
	var step_deg = (end - start) / steps
	for i in steps:
		var a1 = deg_to_rad(start + i * step_deg)
		var a2 = deg_to_rad(start + (i + 1) * step_deg)
		var p1 = Vector3(cos(a1) * wheel_outer_radius, 0, sin(a1) * wheel_outer_radius)
		var p2 = Vector3(cos(a2) * wheel_outer_radius, 0, sin(a2) * wheel_outer_radius)
		var p3 = Vector3(cos(a1) * wheel_inner_radius, 0, sin(a1) * wheel_inner_radius)
		var p4 = Vector3(cos(a2) * wheel_inner_radius, 0, sin(a2) * wheel_inner_radius)
		var t = Vector3(0, wheel_thickness, 0)
		_add_quad(st, p3 + t, p4 + t, p2 + t, p1 + t) # Top
		_add_quad(st, p1, p2, p4, p3) # Bottom
		_add_quad(st, p1, p2, p2 + t, p1 + t) # Outer
		_add_quad(st, p4, p3, p3 + t, p4 + t) # Inner
	st.generate_normals(); return st.commit()

func _add_quad(st, p1, p2, p3, p4):
	st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p3)
	st.add_vertex(p1); st.add_vertex(p3); st.add_vertex(p4)