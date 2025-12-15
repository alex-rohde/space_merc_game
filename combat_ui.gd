extends Control

var combat_manager: CombatManager
var player_crew: Array[CrewMember] = []
var enemies: Array[Enemy] = []

# UI References
@onready var crew_front_container = $VBox/BattlefieldMargin/Battlefield/CrewSide/FrontColumn/Container
@onready var crew_middle_container = $VBox/BattlefieldMargin/Battlefield/CrewSide/MiddleColumn/Container
@onready var crew_back_container = $VBox/BattlefieldMargin/Battlefield/CrewSide/BackColumn/Container
@onready var enemy_front_container = $VBox/BattlefieldMargin/Battlefield/EnemySide/FrontColumn/Container
@onready var enemy_middle_container = $VBox/BattlefieldMargin/Battlefield/EnemySide/MiddleColumn/Container
@onready var enemy_back_container = $VBox/BattlefieldMargin/Battlefield/EnemySide/BackColumn/Container
@onready var hand_container = $VBox/HandMargin/BottomHBox/HandContainer
@onready var energy_label = $VBox/TopBar/HBoxContainer/EnergyLabel
@onready var turn_label = $VBox/TopBar/HBoxContainer/TurnLabel
@onready var end_turn_button = $VBox/TopBar/HBoxContainer/EndTurnButton
@onready var log_text = $VBox/LogMargin/LogScroll/LogText
@onready var draw_pile_count = $VBox/HandMargin/BottomHBox/DrawPileIndicator/DrawPileCount
@onready var discard_pile_count = $VBox/HandMargin/BottomHBox/DiscardPileIndicator/DiscardPileCount

# Preload scenes
var card_ui_scene = preload("res://card_ui.tscn")
var character_display_scene = preload("res://character_display.tscn")
var position_slot_scene = preload("res://position_slot.tscn")

# Game state
var selected_card_ui: CardUI = null
var targeting_mode: bool = false
var selected_crew_for_move: CrewMember = null

func _ready():
	# Create combat manager
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	# Connect signals
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.energy_changed.connect(_on_energy_changed)
	combat_manager.hand_updated.connect(_on_hand_updated)
	combat_manager.crew_died.connect(_on_crew_died)
	combat_manager.deck_updated.connect(_on_deck_updated)
	combat_manager.position_updated.connect(_on_position_updated)
	
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	# Setup test combat
	_setup_test_combat()
	
	await get_tree().process_frame
	add_log("=== COMBAT START ===")

func _setup_test_combat():
	# Create player crew - new names and classes
	var marcus = _create_crew_member("Marcus", "Captain", "captain", "front", 0)
	marcus.slot_index = 0
	var gavin = _create_crew_member("Gavin", "Shield", "shield", "middle", 1)
	gavin.slot_index = 0
	var harold = _create_crew_member("Harold", "Marksman", "marksman", "back", 2)
	harold.slot_index = 0
	
	player_crew = [marcus, gavin, harold]
	
	# Create enemies - also spread across positions
	var pirate1 = _create_enemy("Pirate Gunner", 12, "front", "ranged_only")
	var pirate2 = _create_enemy("Pirate Raider", 15, "middle", "melee_only")
	
	enemies = [pirate1, pirate2]
	
	# Display characters
	_display_characters()
	
	# Start combat
	combat_manager.setup_combat(player_crew, enemies)

func _create_crew_member(cname: String, cclass: String, role: String, pos: String, id: int) -> CrewMember:
	var crew = CrewMember.new()
	add_child(crew)
	crew.crew_name = cname
	crew.crew_class = cclass
	crew.crew_role = role
	crew.position = pos
	crew.crew_id = id
	return crew

func _create_enemy(ename: String, hp: int, pos: String, etype: String = "generic") -> Enemy:
	var enemy = Enemy.new()
	add_child(enemy)
	enemy.enemy_name = ename
	enemy.enemy_type = etype
	enemy.max_health = hp
	enemy.current_health = hp
	enemy.position = pos
	return enemy

func _display_characters():
	# For each position, show characters in their specific slots and fill rest with empty slots
	
	# Crew side
	for pos_name in ["front", "middle", "back"]:
		var container_node
		match pos_name:
			"back":
				container_node = crew_back_container
			"middle":
				container_node = crew_middle_container
			"front":
				container_node = crew_front_container
		
		# Clear all children
		for child in container_node.get_children():
			child.queue_free()
		
		# Get crew in this position
		var crew_in_position = player_crew.filter(func(c): return c.position == pos_name and c.is_alive)
		
		# Create array of 3 slots - fill with characters or empty slots
		for slot_idx in range(3):
			# Check if any crew is in this specific slot
			var crew_in_slot = crew_in_position.filter(func(c): return c.slot_index == slot_idx)
			
			if not crew_in_slot.is_empty():
				# Place character in this slot
				var crew = crew_in_slot[0]
				var display = character_display_scene.instantiate()
				container_node.add_child(display)
				display.setup(crew, true)
				display.character_clicked.connect(_on_character_clicked)
			else:
				# Place empty position slot
				var slot = position_slot_scene.instantiate()
				container_node.add_child(slot)
				slot.setup(pos_name, true, slot_idx)
				slot.slot_clicked.connect(_on_position_slot_clicked)
	
	# Enemy side (similar logic)
	for pos_name in ["front", "middle", "back"]:
		var container_node
		match pos_name:
			"back":
				container_node = enemy_back_container
			"middle":
				container_node = enemy_middle_container
			"front":
				container_node = enemy_front_container
		
		# Clear all children
		for child in container_node.get_children():
			child.queue_free()
		
		# Get enemies in this position
		var enemies_in_position = enemies.filter(func(e): return e.position == pos_name and e.is_alive)
		
		# Create array of 3 slots
		for slot_idx in range(3):
			var enemy_in_slot = enemies_in_position.filter(func(e): return e.get("slot_index") != null and e.slot_index == slot_idx)
			
			if not enemy_in_slot.is_empty():
				var enemy = enemy_in_slot[0]
				var display = character_display_scene.instantiate()
				container_node.add_child(display)
				display.setup(enemy, false)
				display.character_clicked.connect(_on_character_clicked)
			else:
				var slot = position_slot_scene.instantiate()
				container_node.add_child(slot)
				slot.setup(pos_name, false, slot_idx)

func _on_hand_updated(cards: Array):
	# Clear existing card UIs
	for child in hand_container.get_children():
		child.queue_free()
	
	# Create new card UIs
	for i in cards.size():
		var card = cards[i]
		var card_ui = card_ui_scene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card, i)
		card_ui.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(card_ui: CardUI):
	var card = card_ui.card_data
	
	# Check if we can play it
	var owner = _find_crew_by_id(card.owner_id)
	if owner == null or not card.can_play(owner, combat_manager.current_energy):
		add_log("Cannot play %s" % card.card_name)
		return
	
	# Determine if card needs a target
	var needs_target = false
	
	# Cards that need targets: damage cards (except Rally/Protect) and heal cards
	if card.damage > 0 and not card.rally_effect and not card.protect_effect and not card.grenade_effect:
		needs_target = true
	elif card.heal > 0:
		needs_target = true
	elif card.grenade_effect:
		needs_target = true  # Grenade needs a target for AOE center
	
	if needs_target:
		selected_card_ui = card_ui
		targeting_mode = true
		add_log("Select a target for %s" % card.card_name)
	else:
		# Play card without target (Rally, Protect, blocks, energy gain, etc)
		if combat_manager.play_card(card_ui.card_index, null):
			add_log("%s played %s" % [owner.crew_name, card.card_name])

func _on_character_clicked(character):
	# If in targeting mode, handle card targeting
	if targeting_mode and selected_card_ui != null:
		var card = selected_card_ui.card_data
		
		# Validate target
		if card.damage > 0:
			# Attack cards target enemies
			if character is Enemy and character.is_alive:
				if combat_manager.play_card(selected_card_ui.card_index, character):
					var owner = _find_crew_by_id(card.owner_id)
					add_log("%s played %s on %s" % [owner.crew_name, card.card_name, character.enemy_name])
		elif card.heal > 0:
			# Heal cards target crew
			if character is CrewMember and character.is_alive:
				if combat_manager.play_card(selected_card_ui.card_index, character):
					var owner = _find_crew_by_id(card.owner_id)
					add_log("%s played %s on %s" % [owner.crew_name, card.card_name, character.crew_name])
		
		# Exit targeting mode
		selected_card_ui = null
		targeting_mode = false
	
	# If not in targeting mode and clicked a crew member, select for movement
	elif character is CrewMember and character.is_alive and combat_manager.current_state == CombatManager.CombatState.PLAYER_TURN:
		_select_crew_for_movement(character)

func _select_crew_for_movement(crew: CrewMember):
	# Clear previous selection
	_clear_movement_highlights()
	
	selected_crew_for_move = crew
	
	# Determine valid adjacent positions
	var valid_positions = []
	match crew.position:
		"front":
			valid_positions = ["middle"]
		"middle":
			valid_positions = ["front", "back"]
		"back":
			valid_positions = ["middle"]
	
	# Highlight ALL slots in valid positions
	for pos in valid_positions:
		var container_node
		match pos:
			"back":
				container_node = crew_back_container
			"middle":
				container_node = crew_middle_container
			"front":
				container_node = crew_front_container
		
		# Highlight all PositionSlot children
		for child in container_node.get_children():
			if child is PositionSlot:
				child.set_highlighted(true)
	
	add_log("Selected %s (at %s). Click a highlighted position to move (1 energy)" % [crew.crew_name, crew.position])

func _clear_movement_highlights():
	# Clear highlights from all position slots
	for container in [crew_front_container, crew_middle_container, crew_back_container]:
		for child in container.get_children():
			if child is PositionSlot:
				child.set_highlighted(false)
	
	selected_crew_for_move = null

func _on_position_slot_clicked(position_name: String, is_crew_side: bool, slot_index: int):
	if not is_crew_side:
		return  # Only crew can move for now
	
	if selected_crew_for_move != null:
		# Update crew's slot index when moving
		selected_crew_for_move.slot_index = slot_index
		_execute_movement(selected_crew_for_move, position_name)
		_clear_movement_highlights()

func _on_end_turn_pressed():
	add_log("=== ENDING TURN ===")
	combat_manager.end_turn()
	# Wait for enemies to act
	await get_tree().create_timer(2.0).timeout

func _on_turn_started(turn_num: int):
	turn_label.text = "Turn: %d" % turn_num
	add_log("=== TURN %d ===" % turn_num)

func _on_energy_changed(current: int, maximum: int):
	energy_label.text = "Energy: ⚡%d/%d" % [current, maximum]

func _on_deck_updated(draw_count: int, discard_count: int):
	draw_pile_count.text = str(draw_count)
	discard_pile_count.text = str(discard_count)

func _on_crew_died(crew_member: CrewMember):
	add_log("!!! %s HAS FALLEN !!!" % crew_member.crew_name)

func _on_position_updated():
	# Refresh battlefield display when positions change
	_display_characters()

func _on_combat_ended(victory: bool):
	if victory:
		add_log("=== VICTORY ===")
	else:
		add_log("=== DEFEAT ===")
	
	end_turn_button.disabled = true
	
	# Show results
	_show_results(victory)

func _show_results(victory: bool):
	await get_tree().create_timer(1.0).timeout
	
	add_log("\nCrew Status:")
	for crew in player_crew:
		var status = "ALIVE" if crew.is_alive else "DECEASED"
		add_log("  %s: %s (%d/%d HP)" % [crew.crew_name, status, crew.current_health, crew.max_health])
	
	# Show burial options for dead crew
	for crew in player_crew:
		if not crew.is_alive:
			add_log("\nOptions for %s:" % crew.crew_name)
			add_log("  [J] Jettison body (clean deck)")
			add_log("  [B] Bury with honors (memorial card)")

func _execute_movement(crew: CrewMember, new_position: String):
	if combat_manager.move_crew(crew, new_position):
		add_log("%s moved to %s" % [crew.crew_name, new_position])
		# Refresh the battlefield display
		_display_characters()
	else:
		add_log("Cannot move there!")
	
	_clear_movement_highlights()

func _find_crew_by_id(id: int) -> CrewMember:
	for crew in player_crew:
		if crew.crew_id == id:
			return crew
	return null

func add_log(message: String):
	log_text.text += message + "\n"
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = log_text.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		# ESC to cancel movement selection
		if event.keycode == KEY_ESCAPE:
			if selected_crew_for_move != null:
				add_log("Movement cancelled")
				_clear_movement_highlights()
		
		# Burial shortcuts when combat is over
		if combat_manager.current_state == CombatManager.CombatState.COMBAT_END:
			for crew in player_crew:
				if not crew.is_alive:
					if event.keycode == KEY_J:
						combat_manager.jettison_body(crew)
						add_log("Jettisoned %s" % crew.crew_name)
						return
					elif event.keycode == KEY_B:
						var memorial = combat_manager.bury_with_honors(crew)
						add_log("Buried %s, received: %s" % [crew.crew_name, memorial.card_name])
						return
