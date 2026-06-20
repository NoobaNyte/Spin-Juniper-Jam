extends RigidBody3D

@export_group("Wheel Settings")
@export var wheel_radius: float = 20.0
@export var extrusion_depth: float = 1.0 # How "thick" the 3D wheel is

@export_group("Slice Angle Range")
@export var min_angle_degrees: float = 60.0
@export var max_angle_degrees: float = 90.0

@export_group("Quality")
# Higher number = smoother curve on the outside edge of the pie slice
@export var curve_resolution: int = 16

func _ready() -> void:
    # Randomize the seed so we get a different result every time we run
    randomize()
    generate_random_slice()

func generate_random_slice() -> void:
    # 1. Determine the random angle (how much of the pie it takes up)
    var random_angle = randf_range(min_angle_degrees, max_angle_degrees)
    print("Generating slice with angle: ", random_angle)
    
    # 2. Create the CSG Nodes
    var slice_combiner = CSGCombiner3D.new()
    var slice_polygon = CSGPolygon3D.new()
    
    # 3. Calculate the 2D polygon points for the pie slice
    var points = PackedVector2Array()
    
    # Start at the exact center (0,0). This ensures the pivot point is the center of the wheel.
    points.append(Vector2.ZERO)
    
    # Calculate the points along the curved edge of the slice
    var start_angle_rad = 0.0
    var end_angle_rad = deg_to_rad(random_angle)
    
    for i in range(curve_resolution + 1):
        # t goes from 0.0 to 1.0 as we loop
        var t = float(i) / float(curve_resolution)
        var current_angle = lerp(start_angle_rad, end_angle_rad, t)
        
        # Trigonometry to find the X and Y coordinates on the circle
        var x = cos(current_angle) * wheel_radius
        var y = sin(current_angle) * wheel_radius
        
        points.append(Vector2(x, y))
    
    # Godot automatically closes the polygon (connects the last point back to the first),
    # so we don't need to append Vector2.ZERO a second time.
    
    # 4. Apply the shape and thickness to the CSGPolygon3D
    slice_polygon.polygon = points
    slice_polygon.depth = extrusion_depth
    
    # Lay it flat! Pitch it -90 degrees on the X-axis 
    # This turns the local Z extrusion into a global Y extrusion.
    slice_combiner.rotation_degrees.x = -90.0
    
    # 5. Build the hierarchy
    slice_combiner.add_child(slice_polygon)
    add_child(slice_combiner)
    
    # 6. Optional: Give it a random color so you can see it easily if you add more later
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(randf(), randf(), randf())
    slice_polygon.material = material
    
    # 7. Enable collision if you need the wheel to physically interact with a "flipper"
    slice_combiner.use_collision = true