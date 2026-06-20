extends Node3D

# ── Platform Shape ─────────────────────────────────────────────────────────────
@export var pivot_point: Vector3 = Vector3.ZERO
@export var platform_radius: float = 15.0
@export var platform_inner_radius: float = 0.0
@export var platform_thickness: float = 0.3

# ── Section Angle ──────────────────────────────────────────────────────────────
@export var min_section_angle: float = 20.0
@export var max_section_angle: float = 90.0

# ── Rotation ───────────────────────────────────────────────────────────────────
# Degrees/sec. Change at runtime to speed up over time.
@export var rotation_speed_deg: float = 45.0

# Fixed world-space angle where sections are both created and destroyed.
# Sections spawn here, complete one full revolution, and despawn here.
@export var spawn_angle_deg: float = 180.0

# ── Walls ──────────────────────────────────────────────────────────────────────
@export var wall_meshes: Array[Mesh] = []
@export var wall_height: float = 1.5
@export var wall_on_trailing_edge: bool = false
@export var wall_on_leading_edge: bool = true

# ── Visuals ────────────────────────────────────────────────────────────────────
@export var platform_material: Material = null

@export var section_colors: Array[Color] = [Color.WHITE]
@export var sequential_colors: bool = false
var _color_index: int = 0


@export var hole_radius_min: float = 1.5
@export var hole_radius_max: float = 3.0
@export var hole_distance_min: float = 7.0
@export var hole_distance_max: float = 13.0

@export var hole_chance: float = .5

# ── Player reference ───────────────────────────────────────────────────────────
@export var player: CharacterBody3D = null

var _pending_angle: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────
# Internal
# Each entry:
#   "wrapper"         : Node3D       — sits at pivot, rotated each frame
#   "body"            : RigidBody3D  — frozen-kinematic child, holds mesh + collision
#   "section_angle"   : float        — angular width in degrees
#   "world_angle"     : float        — current world-space angle of the TRAILING edge
#                                      (normalised 0–360, increases each frame)
# ─────────────────────────────────────────────────────────────────────────────
var _sections: Array[Dictionary] = []



func _ready() -> void:
	if player:
		player.pivot_point = pivot_point
	# Pick the first section's size and wait for that much space to open up.
	# Since the ring is empty, spawn immediately.
	_pending_angle = _pick_angle()
	_try_spawn()


# ─────────────────────────────────────────────────────────────────────────────
# Per-frame: rotate everything, despawn sections that passed despawn_angle_deg,
# then spawn one new section at spawn_angle_deg if there's a gap there.
# ─────────────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	var deg: float = rotation_speed_deg * delta

	for i in range(_sections.size() - 1, -1, -1):
		var sec: Dictionary = _sections[i]

		sec["wrapper"].rotation_degrees.y = -(spawn_angle_deg + sec["travelled"])
		sec["world_angle"] = fposmod(sec["world_angle"] + deg, 360.0)
		sec["body"].angular_velocity = Vector3(0.0, deg_to_rad(rotation_speed_deg), 0.0)

		sec["travelled"] = sec.get("travelled", 0.0) + deg
		if sec["travelled"] >= 360.0:
			sec["wrapper"].queue_free()
			_sections.remove_at(i)

	# _next_trailing_angle line removed — spawn point is always spawn_angle_deg
	_try_spawn()


# ─────────────────────────────────────────────────────────────────────────────
# Greedily fill the gap at spawn_angle_deg.
# Since sections travel exactly 360° before despawning, the ring should always
# be fully covered. We spawn until arc_covered reaches 360°.
# Angle is biased toward max_section_angle so the fill uses fewer larger pieces.
# ─────────────────────────────────────────────────────────────────────────────
func _try_spawn() -> void:
	if _sections.is_empty():
		_spawn_section(spawn_angle_deg, _pending_angle)
		_pending_angle = _pick_angle()
		return

	var newest: Dictionary = _sections.back()
	var gap: float = newest["travelled"]

	if gap < _pending_angle - 0.01:
		return

	_spawn_section(spawn_angle_deg, _pending_angle)
	_pending_angle = _pick_angle()

func _pick_angle() -> float:
	var t := pow(randf(), 0.35)
	return lerpf(min_section_angle, max_section_angle, t)
	
func _spawn_next_section() -> void:
	var arc_covered: float = 0.0
	for sec in _sections:
		arc_covered += sec["section_angle"]

	var remaining: float = 360.0 - arc_covered
	if remaining <= 0.0:
		return

	var t: float = pow(randf(), 0.35)
	var angle: float = lerpf(min_section_angle, max_section_angle, t)
	angle = min(angle, remaining)

	_spawn_section(spawn_angle_deg, angle)  # always spawn at the fixed angle
	# _next_trailing_angle is NOT advanced here anymore

# ─────────────────────────────────────────────────────────────────────────────
# Spawn one section
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_section(trailing_angle_deg: float, section_angle_deg: float) -> void:
	var wrapper := Node3D.new()
	add_child(wrapper)
	wrapper.global_position = pivot_point
	wrapper.rotation_degrees.y = -trailing_angle_deg

	var body := RigidBody3D.new()
	body.gravity_scale = 0.0
	body.freeze = true
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	wrapper.add_child(body)

	var has_hole: bool = randf() < hole_chance
	
	var picked_hole_radius: float = 0.0
	var picked_hole_dist: float = 0.0
	if has_hole:
		picked_hole_radius = randf_range(hole_radius_min, hole_radius_max)
		picked_hole_dist = randf_range(hole_distance_min, hole_distance_max)
	var mesh := _build_wedge_mesh(section_angle_deg, platform_radius, platform_inner_radius, platform_thickness, 12, picked_hole_radius, picked_hole_dist)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if platform_material:
		mi.material_override = platform_material
	else:
		var mat := StandardMaterial3D.new()
		if section_colors.size() > 0:
			if sequential_colors:
				mat.albedo_color = section_colors[_color_index % section_colors.size()]
				_color_index += 1
			else:
				mat.albedo_color = section_colors[randi() % section_colors.size()]
		else:
			mat.albedo_color = Color(randf(), randf(), randf())
		mi.material_override = mat
	body.add_child(mi)

	var col := CollisionShape3D.new()
	if has_hole:
		col.shape = mesh.create_trimesh_shape() 
	else:
		col.shape = mesh.create_convex_shape()
	
	body.add_child(col)

	if wall_meshes.size() > 0:
		if wall_on_trailing_edge:
			_add_wall(body, 0.0)
		if wall_on_leading_edge:
			_add_wall(body, section_angle_deg)

	_sections.append({
		"wrapper": wrapper,
		"body": body,
		"section_angle": section_angle_deg,
		"world_angle": fposmod(trailing_angle_deg, 360.0),
		"travelled": 0.0,
	})


func _add_wall(body: RigidBody3D, edge_angle_deg: float) -> void:
	var chosen_mesh: Mesh = wall_meshes[randi() % wall_meshes.size()]

	var wall_body := StaticBody3D.new()
	body.add_child(wall_body)

	var mi := MeshInstance3D.new()
	mi.mesh = chosen_mesh
	wall_body.add_child(mi)

	var col := CollisionShape3D.new()
	col.shape = chosen_mesh.create_convex_shape()
	wall_body.add_child(col)

	var rad: float = deg_to_rad(edge_angle_deg)
	wall_body.position = Vector3(
		sin(rad) * platform_radius,
		platform_thickness * 0.5,
		-cos(rad) * platform_radius
	)
	wall_body.rotation_degrees.y = -edge_angle_deg + 90.0
	
	
# Returns the two t values (near, far) where a ray from origin at angle a
# intersects a circle at (cx, cz) with radius r.
# Returns (-1, -1) if no intersection.
func _ray_circle_intersect(a: float, cx: float, cz: float, r: float) -> Vector2:
	var dx := sin(a)
	var dz := -cos(a)
	# Quadratic: t^2 - 2t*(dx*cx + dz*cz) + (cx^2 + cz^2 - r^2) = 0
	var b := -(dx*cx + dz*cz)
	var c := cx*cx + cz*cz - r*r
	var disc := b*b - c
	if disc < 0.0:
		return Vector2(-1.0, -1.0)
	var sq := sqrt(disc)
	var t0 := -b - sq
	var t1 := -b + sq
	if t1 < 0.0:
		return Vector2(-1.0, -1.0)  # hole is behind origin
	return Vector2(max(t0, 0.0), t1)

func _build_wedge_mesh(section_angle_deg: float, outer_r: float, inner_r: float, thickness: float, segments: int = 12, hole_r: float = 0.0, hole_dist: float = 0.0) -> ArrayMesh:	
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var half_t: float = thickness * 0.5
	var steps: int = max(segments, 2)
	var solid: bool = inner_r <= 0.001
	var has_hole: bool = hole_r > 0.001
	var eff_inner: float = inner_r if not solid else 0.0

	var mid_r: float = (outer_r + eff_inner) * 0.5
	
	var mid_a: float = deg_to_rad(section_angle_deg * 0.5)
	var hole_cx: float = sin(mid_a) * hole_dist
	var hole_cz: float = -cos(mid_a) * hole_dist

	var arc_steps: int = steps * 2

	# ── Top and bottom faces ───────────────────────────────────────────────────
	for face in 2:
		var y: float = half_t if face == 0 else -half_t
		var normal: Vector3 = Vector3.UP if face == 0 else Vector3.DOWN

		if not has_hole:
			var fs: int = verts.size()
			if solid:
				verts.append(Vector3(0, y, 0)); normals.append(normal); uvs.append(Vector2(0.5, 0.5))
				for s in range(steps + 1):
					var a := deg_to_rad(section_angle_deg * s / steps)
					verts.append(Vector3(sin(a)*outer_r, y, -cos(a)*outer_r))
					normals.append(normal); uvs.append(Vector2(sin(a)*0.5+0.5, -cos(a)*0.5+0.5))
				for s in range(steps):
					if face == 0: indices.append_array([fs, fs+s+1, fs+s+2])
					else:         indices.append_array([fs, fs+s+2, fs+s+1])
			else:
				for s in range(steps + 1):
					var a := deg_to_rad(section_angle_deg * s / steps)
					var sx := sin(a); var sz := -cos(a)
					verts.append(Vector3(sx*inner_r, y, sz*inner_r)); normals.append(normal); uvs.append(Vector2(sx*inner_r/outer_r*0.5+0.5, sz*inner_r/outer_r*0.5+0.5))
					verts.append(Vector3(sx*outer_r, y, sz*outer_r)); normals.append(normal); uvs.append(Vector2(sx*0.5+0.5, sz*0.5+0.5))
				for s in range(steps):
					var i0: int = fs + s*2
					if face == 0: indices.append_array([i0,i0+1,i0+3,i0,i0+3,i0+2])
					else:         indices.append_array([i0,i0+3,i0+1,i0,i0+2,i0+3])
		else:
			for ai in range(arc_steps):
				var a0: float = deg_to_rad(section_angle_deg * float(ai)     / arc_steps)
				var a1: float = deg_to_rad(section_angle_deg * float(ai + 1) / arc_steps)

				var t0 := _ray_circle_intersect(a0, hole_cx, hole_cz, hole_r)
				var t1 := _ray_circle_intersect(a1, hole_cx, hole_cz, hole_r)

				var out0  := Vector3(sin(a0)*outer_r,   y, -cos(a0)*outer_r)
				var out1  := Vector3(sin(a1)*outer_r,   y, -cos(a1)*outer_r)
				var in0   := Vector3(sin(a0)*eff_inner, y, -cos(a0)*eff_inner)
				var in1   := Vector3(sin(a1)*eff_inner, y, -cos(a1)*eff_inner)

				if t0.x < 0.0 or t1.x < 0.0:
					# Slice doesn't cross hole — full strip
					var b: int = verts.size()
					for v in [in0, in1, out0, out1]:
						verts.append(v); normals.append(normal)
						uvs.append(Vector2(v.x/outer_r*0.5+0.5, v.z/outer_r*0.5+0.5))
					if face == 0: indices.append_array([b,b+2,b+3, b,b+3,b+1])
					else:         indices.append_array([b,b+3,b+2, b,b+1,b+3])
				else:
					# Clamp intersection distances to [eff_inner, outer_r]
					var near0_t: float = clamp(t0.x, eff_inner, outer_r)
					var far0_t:  float = clamp(t0.y, eff_inner, outer_r)
					var near1_t: float = clamp(t1.x, eff_inner, outer_r)
					var far1_t:  float = clamp(t1.y, eff_inner, outer_r)

					var near0 := Vector3(sin(a0)*near0_t, y, -cos(a0)*near0_t)
					var far0  := Vector3(sin(a0)*far0_t,  y, -cos(a0)*far0_t)
					var near1 := Vector3(sin(a1)*near1_t, y, -cos(a1)*near1_t)
					var far1  := Vector3(sin(a1)*far1_t,  y, -cos(a1)*far1_t)

					# Inner strip: platform inner edge to near hole edge
					if near0_t > eff_inner or near1_t > eff_inner:
						var b0: int = verts.size()
						for v in [in0, in1, near0, near1]:
							verts.append(v); normals.append(normal)
							uvs.append(Vector2(v.x/outer_r*0.5+0.5, v.z/outer_r*0.5+0.5))
						if face == 0: indices.append_array([b0,b0+2,b0+3, b0,b0+3,b0+1])
						else:         indices.append_array([b0,b0+3,b0+2, b0,b0+1,b0+3])

					# Outer strip: far hole edge to platform outer edge
					if far0_t < outer_r and far1_t < outer_r:
						var b1: int = verts.size()
						for v in [far0, far1, out0, out1]:
							verts.append(v); normals.append(normal)
							uvs.append(Vector2(v.x/outer_r*0.5+0.5, v.z/outer_r*0.5+0.5))
						if face == 0: indices.append_array([b1,b1+2,b1+3, b1,b1+3,b1+1])
						else:         indices.append_array([b1,b1+3,b1+2, b1,b1+1,b1+3])

	# ── Outer rim wall ─────────────────────────────────────────────────────────
	var ws: int = verts.size()
	for s in range(steps + 1):
		var a := deg_to_rad(section_angle_deg * s / steps)
		var nx := sin(a); var nz := -cos(a)
		verts.append(Vector3(nx*outer_r,  half_t, nz*outer_r)); normals.append(Vector3(nx,0,nz)); uvs.append(Vector2(float(s)/steps, 1.0))
		verts.append(Vector3(nx*outer_r, -half_t, nz*outer_r)); normals.append(Vector3(nx,0,nz)); uvs.append(Vector2(float(s)/steps, 0.0))
	for s in range(steps):
		var i0: int = ws + s*2
		indices.append_array([i0,i0+2,i0+3, i0,i0+3,i0+1])

	# ── Inner rim wall (donut only) ────────────────────────────────────────────
	if not solid:
		var iws: int = verts.size()
		for s in range(steps + 1):
			var a := deg_to_rad(section_angle_deg * s / steps)
			verts.append(Vector3(sin(a)*inner_r,  half_t, -cos(a)*inner_r)); normals.append(Vector3(-sin(a),0,cos(a))); uvs.append(Vector2(float(s)/steps, 1.0))
			verts.append(Vector3(sin(a)*inner_r, -half_t, -cos(a)*inner_r)); normals.append(Vector3(-sin(a),0,cos(a))); uvs.append(Vector2(float(s)/steps, 0.0))
		for s in range(steps):
			var i0: int = iws + s*2
			indices.append_array([i0,i0+3,i0+2, i0,i0+1,i0+3])

	# ── Hole rim wall ──────────────────────────────────────────────────────────
	if has_hole:
			var hws: int = verts.size()
			var rim_pairs: Array = []  # each entry: [top_pos, bot_pos, normal]

			for s in range(arc_steps + 1):
				var a := PI * 2.0 * s / arc_steps
				var nx: float = sin(a)
				var nz: float = cos(a)
				var px: float = hole_cx + nx * hole_r
				var pz: float = hole_cz + nz * hole_r
				var dist: float = sqrt(px * px + pz * pz)

				if dist <= outer_r + 0.001 and dist >= eff_inner - 0.001:
					rim_pairs.append([
						Vector3(px,  half_t, pz),
						Vector3(px, -half_t, pz),
						Vector3(-nx, 0.0, -nz)
					])

			for pair in rim_pairs:
				verts.append(pair[0]); normals.append(pair[2]); uvs.append(Vector2(0.0, 1.0))
				verts.append(pair[1]); normals.append(pair[2]); uvs.append(Vector2(0.0, 0.0))

			var seg_count: int = rim_pairs.size()
			for s in range(seg_count - 1):
				# Check if this segment crosses outside the platform — skip it if so
				var p0: Vector3 = rim_pairs[s][0]
				var p1: Vector3 = rim_pairs[s + 1][0]
				var mid_x: float = (p0.x + p1.x) * 0.5
				var mid_z: float = (p0.z + p1.z) * 0.5
				var mid_dist: float = sqrt(mid_x * mid_x + mid_z * mid_z)
				if mid_dist > outer_r or mid_dist < eff_inner:
					continue
				var i0: int = hws + s * 2
				indices.append_array([i0, i0+3, i0+2, i0, i0+1, i0+3])

	# ── Flat edge caps ─────────────────────────────────────────────────────────
	for edge in 2:
		var a := deg_to_rad(0.0 if edge == 0 else section_angle_deg)
		var edge_dir := Vector3(sin(a), 0, -cos(a))
		var en: Vector3 = -edge_dir if edge == 0 else edge_dir
		var es: int = verts.size()
		var p_in: Vector3 = edge_dir * eff_inner
		var p_out: Vector3 = edge_dir * outer_r
		verts.append_array([p_in+Vector3(0,half_t,0), p_out+Vector3(0,half_t,0), p_out+Vector3(0,-half_t,0), p_in+Vector3(0,-half_t,0)])
		for _i in 4: normals.append(en)
		uvs.append_array([Vector2(0,1), Vector2(1,1), Vector2(1,0), Vector2(0,0)])
		if edge == 0: indices.append_array([es,es+2,es+1, es,es+3,es+2])
		else:         indices.append_array([es,es+1,es+2, es,es+2,es+3])

	var arr := Array(); arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs;   arr[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am
