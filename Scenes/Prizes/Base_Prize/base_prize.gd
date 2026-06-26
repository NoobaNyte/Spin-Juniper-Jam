extends Node3D
class_name BasePrize

@export_group("Prize Data")
@export var price: int = 0
var price_label: Sprite3D
@export var quantity_owned: int = 0:
	set(value):
		quantity_owned = value
		prize_popups_ui.update_text_boxes(quantity_owned, item_name, item_description)

@export var item_name: String = "EMPTY NAME"
@export var item_description: String = "EMPTY DESCRIPTION"

@export_group("String Settings")
@export var segment_height: float = 2.0
@export var segment_offset: float = -0.3

const string_piece_file_path: String = "res://Scenes/Prizes/Base_Prize/shop_string_segment.tscn"
var string_piece: PackedScene

var prize_popups_ui
var input_prompt_ui
var should_be_hidden: bool = true # used to prevent from becoming visible again when resetting (in reset_prize method, it could run after you've left the prize area and everything else is faded out )
var bought: bool = false # used to update the quantity owned in each individual prize script
var on_buy_cooldown: bool = false # used to disable buying the item until a new one is spawned in

# --- VARIABLES FOR RESPAWNING ---
var bottom_anchor_pin: PinJoint3D
var lowest_string_segment: RigidBody3D
var current_prize_node: RigidBody3D

# Memory variables to perfectly restore the prize
var original_prize_scale: Vector3
var original_prize_rotation: Vector3
var original_prize_position: Vector3

func _ready() -> void:
	PlayerGlobals.show_prize_prices.connect(on_show_prize_prices)
	PlayerGlobals.hide_prize_prices.connect(on_hide_prize_prices)
	PlayerGlobals.reset_game.connect(restore_original_position)
	
	prize_popups_ui = UI.get_node("PrizePopups")
	input_prompt_ui = UI.get_node("InputPrompt")
	current_prize_node = $Prize/Prize
	
	# Save the pristine transforms so we can perfectly recreate it
	original_prize_scale = current_prize_node.scale
	original_prize_rotation = current_prize_node.rotation
	original_prize_position = current_prize_node.global_position

	string_piece = preload(string_piece_file_path)
	if string_piece:
		gen_strings()

func update_price():
	price_label = find_child("PriceLabel", true, false)
	price_label.update_price_label()

func buy_prize():
	if on_buy_cooldown: return
	
	if PlayerGlobals.tickets >= price:
		bought = true
		on_buy_cooldown = true
		PlayerGlobals.tickets -= price
		fade_out_prize_prices()
		release_prize()

func release_prize() -> void:
	if not is_instance_valid(bottom_anchor_pin):
		return
		
	# 1. STOP THE HESITATION
	current_prize_node.set_collision_layer_value(1, false)
	current_prize_node.set_collision_mask_value(1, false)
	
	current_prize_node.set_collision_layer_value(2, true)
	current_prize_node.set_collision_mask_value(2, true)
	
	# 2. Snip the BOTTOM string so the prize falls
	bottom_anchor_pin.queue_free()
	
	# 3. Wait while it drops and bounces
	await get_tree().create_timer(0.7).timeout
	
	# --- NEW: Freeze physics so it doesn't fight the Tween! ---
	current_prize_node.freeze = true
	
	# 4. Smooth scale down
	var tween = create_tween()
	tween.tween_property(current_prize_node, "scale", Vector3(0.01, 0.01, 0.01), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# 5. Hide the prize completely
	current_prize_node.hide()
	
	# 6. Wait exactly 1 second before magically restoring it
	await get_tree().create_timer(1.0).timeout
	
	# 7. Restore the original prize!
	reset_prize()

func reset_prize() -> void:
	if not should_be_hidden:
		on_show_prize_prices()
	var string_bottom: Marker3D = $Prize/StringBottom
	
	# 1. Zero out momentum
	current_prize_node.linear_velocity = Vector3.ZERO
	current_prize_node.angular_velocity = Vector3.ZERO
	
	# 2. Teleport it back to its original spot
	current_prize_node.global_position = original_prize_position
	current_prize_node.rotation = original_prize_rotation
	
	# 3. Force scale to tiny
	current_prize_node.scale = Vector3(0.01, 0.01, 0.01)
	
	# 4. Unhide and smoothly scale it back up FIRST
	current_prize_node.show()
	var tween = create_tween()
	tween.tween_property(current_prize_node, "scale", original_prize_scale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# --- NEW: We MUST wait for the animation to finish before turning physics back on ---
	await tween.finished
	
	# 5. NOW restore the collision layers back to layer 1 normal physics
	current_prize_node.set_collision_layer_value(2, false)
	current_prize_node.set_collision_mask_value(2, false)
	
	current_prize_node.set_collision_layer_value(1, true)
	current_prize_node.set_collision_mask_value(1, true)
	
	# 6. Re-create the pin to hold it up
	bottom_anchor_pin = PinJoint3D.new()
	add_child(bottom_anchor_pin)
	bottom_anchor_pin.global_position = string_bottom.global_position
	bottom_anchor_pin.node_a = current_prize_node.get_path()
	bottom_anchor_pin.node_b = lowest_string_segment.get_path()

	# --- NEW: Unfreeze it now that everything is safely attached! ---
	current_prize_node.freeze = false
	on_buy_cooldown = false

func gen_strings():
	var string_bottom: Marker3D = $Prize/StringBottom
	var string_top: Marker3D = $Prize/StringTop
	var prize: RigidBody3D = current_prize_node
	
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
		
		# Save the bottom pin and lowest string on the first loop
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
			
			var top_pin = PinJoint3D.new()
			add_child(top_pin)
			top_pin.global_position = anchor.global_position
			top_pin.node_a = prev_body.get_path()
			top_pin.node_b = anchor.get_path()
			
			break

func _on_selection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		prize_popups_ui.update_text_boxes(quantity_owned, item_name, item_description)
		prize_popups_ui.fade_in(prize_popups_ui)
		input_prompt_ui.change_input_text_to("BUY")
		input_prompt_ui.fade_in(input_prompt_ui)

func _on_selection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		prize_popups_ui.fade_out(prize_popups_ui)
		input_prompt_ui.fade_out(input_prompt_ui)

func on_show_prize_prices():
	should_be_hidden = false
	price_label.fade_in(price_label)

func on_hide_prize_prices():
	should_be_hidden = true
	fade_out_prize_prices()

func fade_out_prize_prices():
	price_label.fade_out(price_label)

func restore_original_position():
	await get_tree().create_timer(0.2).timeout # wait for scene to be fully rotated first before trying to restore positions
	# 1. Zero out momentum
	current_prize_node.linear_velocity = Vector3.ZERO
	current_prize_node.angular_velocity = Vector3.ZERO
	
	# 2. Teleport it back to its original spot
	current_prize_node.global_position = original_prize_position
	current_prize_node.rotation = original_prize_rotation

	var all_children = get_children()
	for child in all_children:
		if child is RigidBody3D:
			child.reset_transform()
