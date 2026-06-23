extends Node3D
class_name BasePrize

@export_group("Prize Data")
@export var price: int = 0
var price_label: Sprite3D
@export var quantity_owned: int = 0
@export var item_name: String = "EMPTY NAME"
@export var item_description: String = "EMPTY DESCRIPTION"

@export_group("String Settings")
## How tall each standard string segment is.
@export var segment_height: float = 2.0
## Negative values create overlap between joints, positive values create gaps.
@export var segment_offset: float = -0.3

const string_piece_file_path: String = "res://Scenes/Prizes/Base_Prize/shop_string_segment.tscn"
var string_piece: PackedScene

func _ready() -> void:
	price_label = find_child("PriceLabel", true, false)
	price_label.update_price()
	string_piece = preload(string_piece_file_path)
	if string_piece:
		gen_strings()
	
func gen_strings():
	var string_bottom: Marker3D = $Prize/StringBottom
	var string_top: Marker3D = $Prize/StringTop
	var prize: RigidBody3D = $Prize/Prize
	
	if not string_bottom or not string_top or not prize:
		push_error("Missing required nodes for string generation!")
		return

	# Track our vertical progress and previous connected object
	var current_y: float = string_bottom.global_position.y
	var end_y: float = string_top.global_position.y
	
	# The X and Z coordinates never change, they just follow the bottom marker
	var base_x = string_bottom.global_position.x
	var base_z = string_bottom.global_position.z
	
	var prev_body: Node3D = prize
	
	while current_y < end_y:
		var is_last = false
		var actual_height = segment_height
		
		# Check if the next standard segment would breach the top marker
		if current_y + actual_height >= end_y:
			# Shave the height down to fit perfectly
			actual_height = end_y - current_y
			is_last = true
			
		# 1. Instantiate the Segment
		var seg = string_piece.instantiate() as RigidBody3D
		add_child(seg)
		seg.global_position = Vector3(base_x, current_y, base_z)
		
		# Set the height and call the math function we built earlier
		seg.height = actual_height
		if seg.has_method("set_height"):
			seg.set_height()
			
		# 2. Pin it to the previous body
		var pin = PinJoint3D.new()
		add_child(pin)
		# Place the pin at the exact bottom of the current segment
		pin.global_position = seg.global_position
		pin.node_a = prev_body.get_path()
		pin.node_b = seg.get_path()
		
		# 3. Step up for the next iteration
		prev_body = seg
		current_y += (actual_height + segment_offset)
		
		# 4. If this was the last piece, anchor it to the ceiling!
		if is_last:
			var anchor = StaticBody3D.new()
			add_child(anchor)
			anchor.global_position = Vector3(base_x, end_y, base_z)
			
			# Add a disabled collider (Godot prefers physics bodies to have shapes)
			var anchor_shape = CollisionShape3D.new()
			var shape_res = SphereShape3D.new()
			shape_res.radius = 0.1
			anchor_shape.shape = shape_res
			anchor_shape.disabled = true
			anchor.add_child(anchor_shape)
			
			# Final pin attaching the last segment to the static ceiling anchor
			var top_pin = PinJoint3D.new()
			add_child(top_pin)
			top_pin.global_position = anchor.global_position
			top_pin.node_a = prev_body.get_path()
			top_pin.node_b = anchor.get_path()
			
			break # Safety exit

func _on_selection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		# fade price label
		price_label.fade_in(price_label)

		# fade UI
		var prize_popups_ui = UI.get_node("PrizePopups")
		prize_popups_ui.update_text_boxes(quantity_owned, item_name, item_description)
		prize_popups_ui.fade_in(prize_popups_ui)


func _on_selection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		# fade price label
		price_label.fade_out(price_label)

		# fade UI
		var prize_popups_ui = UI.get_node("PrizePopups")
		prize_popups_ui.fade_out(prize_popups_ui)
