extends CSGCombiner3D

@onready var hole_test = $HoleTest

func _ready() -> void:
	do_hole_test()

func do_hole_test():
	await get_tree().create_timer(2).timeout
	print("moving hole!")
	
	# 1. Toggle collision OFF before moving
	use_collision = false
	
	# 2. Move the hole cutter
	hole_test.position.z = -50
	
	# 3. Toggle collision ON to force a full CSG and physics rebuild
	use_collision = true
