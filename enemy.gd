extends Node
class_name Enemy

signal health_changed(new_health, max_health)
signal died(enemy)
signal intent_changed(new_intent)
signal block_changed(new_block)

@export var enemy_name: String = "Space Pirate"
@export var enemy_type: String = "generic"  # generic, melee_only, ranged_only
@export var max_health: int = 15
@export var current_health: int = 15
@export var is_alive: bool = true
@export var position: String = "front"  # front, back
@export var slot_index: int = 0  # Which slot (0-3)

var current_block: int = 0
var taunted_by: CrewMember = null  # If taunted, must attack this crew member

# AI intent system - what the enemy plans to do next turn
enum Intent { ATTACK, DEFEND, RANGED_ATTACK, SPECIAL }
var current_intent: Intent = Intent.ATTACK
var intent_value: int = 0  # How much damage/block

func _ready():
	_decide_next_action()

func take_damage(amount: int, is_ranged_attack: bool = false):
	# Apply accuracy penalty if ranged attack against back line with front line protection
	var actual_damage = amount
	if is_ranged_attack and position == "back":
		# Check if there's a front line protecting (simplified for prototype)
		# In full game, check if any enemies are in front
		if randf() < 0.3:  # 30% miss chance
			print("%s evades the ranged attack!" % enemy_name)
			return
	
	var damage_taken = max(0, actual_damage - current_block)
	current_block = max(0, current_block - actual_damage)
	
	current_health -= damage_taken
	health_changed.emit(current_health, max_health)
	
	print("%s takes %d damage! (%d/%d HP)" % [enemy_name, damage_taken, current_health, max_health])
	
	if current_health <= 0 and is_alive:
		die()

func add_block(amount: int):
	current_block += amount
	print("%s gains %d block" % [enemy_name, amount])
	block_changed.emit(current_block)

func reset_block():
	current_block = 0
	block_changed.emit(current_block)

func die():
	is_alive = false
	current_health = 0
	died.emit(self)
	print("%s has been defeated!" % enemy_name)

func take_turn(player_crew: Array, all_enemies: Array = []):
	if not is_alive:
		return
	
	# Melee-only enemies try to move forward if not in front position
	if enemy_type == "melee_only" and position != "front":
		# Find first available slot in front position
		var front_enemies = all_enemies.filter(func(e): return e.is_alive and e.position == "front" and e != self)
		var occupied_slots = front_enemies.map(func(e): return e.slot_index)
		
		# Find first empty slot (0-2)
		var target_slot = 0
		for i in range(3):
			if not i in occupied_slots:
				target_slot = i
				break
		
		print("⬆️ %s (melee-only) moves forward to engage! (slot %d)" % [enemy_name, target_slot])
		position = "front"
		slot_index = target_slot
	
	match current_intent:
		Intent.ATTACK:
			_perform_melee_attack(player_crew)
		Intent.RANGED_ATTACK:
			_perform_ranged_attack(player_crew)
		Intent.DEFEND:
			add_block(intent_value)
	
	# Decide next action after completing this one
	_decide_next_action()

func _perform_melee_attack(player_crew: Array):
	var target = null
	
	# If taunted, MUST attack the taunting crew member
	if taunted_by and taunted_by.is_alive:
		target = taunted_by
		print("😡 %s is taunted and must attack %s!" % [enemy_name, target.crew_name])
	else:
		# Normal targeting: front line first, then middle, then back
		var targets = player_crew.filter(func(c): return c.is_alive and c.position == "front")
		if targets.is_empty():
			targets = player_crew.filter(func(c): return c.is_alive and c.position == "middle")
		if targets.is_empty():
			targets = player_crew.filter(func(c): return c.is_alive and c.position == "back")
		
		if not targets.is_empty():
			target = targets.pick_random()
	
	if target:
		print("⚔️ %s melee attacks %s for %d damage!" % [enemy_name, target.crew_name, intent_value])
		target.take_damage(intent_value)
	
	# Clear taunt after attacking
	taunted_by = null

func _perform_ranged_attack(player_crew: Array):
	var target = null
	
	# If taunted, MUST attack the taunting crew member
	if taunted_by and taunted_by.is_alive:
		target = taunted_by
		print("😡 %s is taunted and must attack %s!" % [enemy_name, target.crew_name])
	else:
		# Can target anyone, prefer back line
		var targets = player_crew.filter(func(c): return c.is_alive)
		if not targets.is_empty():
			target = targets.pick_random()
	
	if target:
		print("🏹 %s shoots %s for %d damage!" % [enemy_name, target.crew_name, intent_value])
		target.take_damage(intent_value)
	
	# Clear taunt after attacking
	taunted_by = null

func _decide_next_action():
	# AI decision based on enemy type
	if enemy_type == "melee_only":
		# Melee-only enemies: Attack or Defend, never ranged
		var roll = randf()
		if roll < 0.7:
			current_intent = Intent.ATTACK
			intent_value = randi_range(5, 8)
		else:
			current_intent = Intent.DEFEND
			intent_value = randi_range(4, 7)
	elif enemy_type == "ranged_only":
		# Ranged-only enemies: Ranged attack or Defend, never melee
		var roll = randf()
		if roll < 0.7:
			current_intent = Intent.RANGED_ATTACK
			intent_value = randi_range(4, 6)
		else:
			current_intent = Intent.DEFEND
			intent_value = randi_range(3, 5)
	else:
		# Generic enemies: Can do anything
		var roll = randf()
		if roll < 0.5:
			current_intent = Intent.ATTACK
			intent_value = randi_range(4, 8)
		elif roll < 0.8:
			current_intent = Intent.RANGED_ATTACK
			intent_value = randi_range(3, 6)
		else:
			current_intent = Intent.DEFEND
			intent_value = randi_range(4, 7)
	
	intent_changed.emit(current_intent)
	print("%s intends to: %s (%d)" % [enemy_name, Intent.keys()[current_intent], intent_value])

func get_intent_string() -> String:
	match current_intent:
		Intent.ATTACK:
			return "Attack: %d" % intent_value
		Intent.RANGED_ATTACK:
			return "Ranged: %d" % intent_value
		Intent.DEFEND:
			return "Defend: +%d Block" % intent_value
		_:
			return "Unknown"
