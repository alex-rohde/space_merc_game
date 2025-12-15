extends Node

var combat_manager: CombatManager
var player_crew: Array[CrewMember] = []
var enemies: Array[Enemy] = []

func _ready():
	# Create combat manager
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	combat_manager.combat_ended.connect(_on_combat_ended)
	
	# Create player crew
	var fighter = _create_crew_member("Marcus", "fighter", "front", 0)
	var tank = _create_crew_member("Tank", "tank", "front", 1)
	var sniper = _create_crew_member("Rifle", "sniper", "back", 2)
	
	player_crew = [fighter, tank, sniper]
	
	# Create enemies
	var pirate1 = _create_enemy("Pirate Gunner", 12, "front")
	var pirate2 = _create_enemy("Pirate Raider", 15, "front")
	
	enemies = [pirate1, pirate2]
	
	# Start combat
	combat_manager.setup_combat(player_crew, enemies)
	
	# Demo: Auto-play a simple combat
	print("\n=== STARTING AUTO-COMBAT DEMO ===\n")
	_run_demo_combat()

func _create_crew_member(name: String, role: String, pos: String, id: int) -> CrewMember:
	var crew = CrewMember.new()
	add_child(crew)
	crew.crew_name = name
	crew.crew_role = role
	crew.position = pos
	crew.crew_id = id
	return crew

func _create_enemy(name: String, hp: int, pos: String) -> Enemy:
	var enemy = Enemy.new()
	add_child(enemy)
	enemy.enemy_name = name
	enemy.max_health = hp
	enemy.current_health = hp
	enemy.position = pos
	return enemy

func _run_demo_combat():
	# Simple demo: play cards automatically until combat ends
	await get_tree().create_timer(1.0).timeout
	
	while combat_manager.current_state == CombatManager.CombatState.PLAYER_TURN:
		# Try to play cards from hand
		var played_card = false
		for i in range(combat_manager.hand.size() - 1, -1, -1):
			var card = combat_manager.hand[i]
			if card.energy_cost <= combat_manager.current_energy and not card.is_dead_card:
				# Find alive enemy to target
				var alive_enemies = enemies.filter(func(e): return e.is_alive)
				var target = alive_enemies[0] if not alive_enemies.is_empty() else null
				
				if combat_manager.play_card(i, target):
					played_card = true
					await get_tree().create_timer(0.3).timeout
					break
		
		if not played_card:
			# No more playable cards, end turn
			combat_manager.end_turn()
			await get_tree().create_timer(1.0).timeout

func _on_combat_ended(victory: bool):
	print("\n=== COMBAT COMPLETE ===")
	if victory:
		print("The crew is victorious!")
	else:
		print("The crew has been defeated...")
	
	# Show crew status
	print("\nCrew Status:")
	for crew in player_crew:
		var status = "ALIVE" if crew.is_alive else "DECEASED"
		print("  %s: %s (%d/%d HP)" % [crew.crew_name, status, crew.current_health, crew.max_health])
	
	# Demo burial system if anyone died
	for crew in player_crew:
		if not crew.is_alive:
			print("\nOptions for %s:" % crew.crew_name)
			print("  1. Jettison body (clean deck immediately)")
			print("  2. Bury with honors (get memorial card)")
			
			# For demo, let's bury them
			var memorial = combat_manager.bury_with_honors(crew)
			print("Received: %s" % memorial.card_name)

func _input(event):
	# Manual testing controls
	if event.is_action_pressed("ui_accept") and combat_manager.current_state == CombatManager.CombatState.PLAYER_TURN:
		# Space bar: end turn manually
		combat_manager.end_turn()
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				# Number keys: play card at that index
				var index = event.keycode - KEY_1
				if index < combat_manager.hand.size():
					var alive_enemies = enemies.filter(func(e): return e.is_alive)
					var target = alive_enemies[0] if not alive_enemies.is_empty() else null
					combat_manager.play_card(index, target)
