extends Node

func _ready() -> void:
	# Wait one frame to ensure the entire scene tree is loaded and ready.
	await get_tree().create_timer(0.01).timeout
	
	print("--- PHYSICS DEBUG REPORT ---")
	
	var player = get_tree().get_first_node_in_group("Player")
	var boulder_trap = find_node_by_name(get_tree().current_scene, "BoulderTrap")

	if player:
		print_node_info(player, "Player Body")
		var hurtbox = player.get_node_or_null("HurtboxComponent")
		if hurtbox:
			print_node_info(hurtbox, "Player Hurtbox")
		else:
			print("!! Player Hurtbox not found.")
	else:
		print("!! Player node not found in group 'Player'.")

	if boulder_trap:
		var trigger = boulder_trap.get_node_or_null("PlayerTrigger")
		if trigger:
			print_node_info(trigger, "Boulder Trap Trigger")
		else:
			print("!! PlayerTrigger not found in BoulderTrap.")
		
		var boulder = boulder_trap.get_node_or_null("Boulder")
		if boulder:
			print_node_info(boulder, "Boulder")
		else:
			print("!! Boulder not found in BoulderTrap.")
	else:
		print("!! BoulderTrap node not found in the scene.")
	
	print("--- END OF REPORT ---")


func print_node_info(node: Node, label: String) -> void:
	var text = "- %s (%s):"
	print(text % [label, node.name])
	
	if node is CollisionObject2D:
		var physics_node: CollisionObject2D = node
		text = "\tCollision Layer: %s"
		print(text % physics_node.collision_layer)
		text = "\tCollision Mask:  %s"
		print(text % physics_node.collision_mask)
	else:
		print("\tNode is not a CollisionObject2D.")


func find_node_by_name(start_node: Node, node_name: String) -> Node:
	if not start_node:
		return null
	
	if start_node.name == node_name:
		return start_node
	
	for child in start_node.get_children():
		var found = find_node_by_name(child, node_name)
		if found:
			return found
	
	return null
