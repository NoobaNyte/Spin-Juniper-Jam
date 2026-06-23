extends Node3D
class_name BasePrize

@export_group("Prize Data")
@export var price: int = 0
var price_label: Sprite3D
@export var quantity_owned: int = 0
@export var item_name: String = "EMPTY NAME"
@export var item_description: String = "EMPTY DESCRIPTION"

@export_group("String Settings")
@export var segment_height: float = 2.0
@export var segment_offset: float = -0.3

const string_piece_file_path: String = "res://Scenes/Prizes/Base_Prize/shop_string_segment.tscn"
var string_piece: PackedScene

# --- NEW VARIABLES FOR RESPAWNING ---
var bottom_anchor_pin: PinJoint3D
var lowest_string_segment: RigidBody3D
var current_prize_node: RigidBody3D
var prize_template: Node # Holds a clean backup copy of the prize

func _ready() -> void:
	PlayerGlobals.show_prize_prices.connect(on_show_prize_prices)
	PlayerGlobals.hide_prize_prices.connect(on_hide_prize_prices)
	
	# Save the active prize and create a clean backup for respawning later
	current_prize_node = $Prize/Prize
	prize_template = current_prize_node.duplicate()

	string_piece = preload(string_piece_file_path)
	if string_piece:
		gen_strings()

func update_price():
	price_label = find_child("PriceLabel", true, false)
	price_label.update_price_label()

func buy_prize():
	if PlayerGlobals.tickets >= price:
		PlayerGlobals.tickets -= price
		release_prize()

# ==========================================
# NEW: The Animated Release Sequence
# ==========================================
func release_prize() -> void:
	if not is_instance_valid(bottom_anchor_pin):
		return # Prevents crashing if they spam the interact button
		
	# 1. Snip the BOTTOM string so the prize falls
	bottom_anchor_pin.queue_free()
	
	# 2. Switch collision layer to 2 (disabling layer 1)
	current_prize_node.set_collision_layer_value(1, false)
	current_prize_node.set_collision_layer_value(2, true)
	
	# 3. Wait 2 seconds while it drops and bounces
	await get_tree().create_timer(2.0).timeout
	
	# 4. Smooth scale down to 0
	var tween = create_tween()
	# Using TRANS_BACK gives it a slight "pop" before shrinking!
	tween.tween_property(current_prize_node, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# (You can trigger your particle emitter here!)
	
	# 5. Hide the prize completely
	current_prize_node.hide()
	
	# 6. Wait 2 seconds before restocking
	await get_tree().create_timer(2.0).timeout
	
	# 7. Restock!
	respawn_prize()

func respawn_prize() -> void:
	# Delete the old invisible prize
	if is_instance_valid(current_prize_node):
		current_prize_node.queue_free()
		
	# Spawn a fresh copy from our template
	current_prize_node = prize_template.duplicate()
	$Prize.add_child(current_prize_node)
	
	# Move it exactly to the string bottom marker
	var string_bottom: Marker3D = $Prize/StringBottom
	current_prize_node.global_position = string_bottom.global_position
	
	# Re-pin the new prize to the lowest string segment!
	bottom_anchor_pin = PinJoint3D.new()
	add_child(bottom_anchor_pin)
	bottom_anchor_pin.global_position = string_bottom.global_position
	bottom_anchor_pin.node_a = current_prize_node.get_path()
	bottom_anchor_pin.node_b = lowest_string_segment.get_path()


func gen_strings():
	var string_bottom: Marker3D = $Prize/StringBottom
	var string_top: Marker3D = $Prize/StringTop
	var prize: RigidBody3D = current_prize_node # Use our tracked variable
	
	if not string_bottom or not string_top or not prize:
		push_error("Missing required nodes for string generation!")
		return

	var current_y: float = string_bottom.global_position.y
	var end_y: float = string_top.global_position.y
	
	var base_x = string_bottom.global_position.x
	var base_z = string_bottom.global_position.z
	
	var prev_body: Node3D = prize
	
	while current_y < end_y:
		var is_last = false
		var actual_height = segment_height
		
		if current_y + actual_height >= end_y:
			actual_height = end_y - current_y
			is_last = true
			
		var seg = string_piece.instantiate() as RigidBody3D
		add_child(seg)
		seg.global_position = Vector3(base_x, current_y, base_z)
		
		seg.height = actual_height
		if seg.has_method("set_height"):
			seg.set_height()
			
		var pin = PinJoint3D.new()
		add_child(pin)
		pin.global_position = seg.global_position
		pin.node_a = prev_body.get_path()
		pin.node_b = seg.get_path()
		
		# --- NEW: Save the bottom pin and lowest string on the first loop ---
		if prev_body == current_prize_node:
			bottom_anchor_pin = pin
			lowest_string_segment = seg
		
		prev_body = seg
		current_y += (actual_height + segment_offset)
		
		if is_last:
			var anchor = StaticBody3D.new()
			add_child(anchor)
			anchor.global_position = Vector3(base_x, end_y, base_z)
			
			var anchor_shape = CollisionShape3D.new()
			var shape_res = SphereShape3D.new()
			shape_res.radius = 0.1
			anchor_shape.shape = shape_res
			anchor_shape.disabled = true
			anchor.add_child(anchor_shape)
			
			# Pin the top string to the ceiling (we don't need to save this one anymore)
			var top_pin = PinJoint3D.new()
			add_child(top_pin)
			top_pin.global_position = anchor.global_position
			top_pin.node_a = prev_body.get_path()
			top_pin.node_b = anchor.get_path()
			
			break

func _on_selection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		var prize_popups_ui = UI.get_node("PrizePopups")
		prize_popups_ui.update_text_boxes(quantity_owned, item_name, item_description)
		prize_popups_ui.fade_in(prize_popups_ui)

func _on_selection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		var prize_popups_ui = UI.get_node("PrizePopups")
		prize_popups_ui.fade_out(prize_popups_ui)

func on_show_prize_prices():
	price_label.fade_in(price_label)

func on_hide_prize_prices():
	price_label.fade_out(price_label)
