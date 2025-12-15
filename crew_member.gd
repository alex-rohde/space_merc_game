extends Node
class_name CrewMember

signal health_changed(new_health, max_health)
signal died(crew_member)
signal position_changed(new_position)
signal block_changed(new_block)

# Crew stats
@export var crew_name: String = "Recruit"
@export var crew_class: String = "Fighter"  # Class name displayed to player
@export var max_health: int = 20
@export var current_health: int = 20
@export var crew_role: String = "fighter"  # fighter, tank, sniper, medic, engineer
@export var position: String = "front"  # front, middle, back
@export var slot_index: int = 0  # Which slot in the position (0-3)
@export var is_alive: bool = true
@export var crew_id: int = 0

# Block/armor for this turn
var current_block: int = 0

# Status effects
var damage_boost: int = 0  # Temporary damage boost (from Rally, etc)
var defense_boost: int = 0  # Temporary defense boost

# Cards this crew member contributes to the deck
var starting_cards: Array[Card] = []

func _ready():
	_initialize_starting_cards()

func _initialize_starting_cards():
	# Each crew role gets a different starting deck
	match crew_role:
		"captain":  # Marcus - Captain
			starting_cards = [
				_create_card("Slash", 1, "Deal 6 damage", "attack", 6, false, "any"),
				_create_card("Slash", 1, "Deal 6 damage", "attack", 6, false, "any"),
				_create_card("Slash", 1, "Deal 6 damage", "attack", 6, false, "any"),
				_create_special_card("Rally", 1, "Boost damage and block of cards in hand by 1 this turn", "support", {"rally": true}),
				_create_special_card("Heroic Strike", 2, "Deal 8 damage. If used from middle, move to front", "attack", {"damage": 8, "requires_position": "middle_front", "heroic_strike": true}),
			]
		"shield":  # Gavin - Shield
			starting_cards = [
				_create_card("Shield Bash", 2, "Deal 4 damage, gain 6 block", "attack", 4, false, "front", 6),
				_create_card("Shield Bash", 2, "Deal 4 damage, gain 6 block", "attack", 4, false, "front", 6),
				_create_special_card("Protect", 1, "Move to front, give 7 block to all front crew", "defense", {"block": 7, "protect": true, "requires_position": "middle_front"}),
				_create_special_card("Taunt", 1, "Force target enemy to attack you this turn", "support", {"taunt": true}),
				_create_special_card("Grenade", 3, "Deal 4 damage to target and adjacent enemies (Front only)", "attack", {"damage": 4, "requires_position": "front", "grenade": true}),
			]
		"marksman":  # Harold - Marksman
			starting_cards = [
				_create_card("Standard Shot", 2, "Deal 8 damage (Middle/Back only)", "attack", 8, true, "middle_back"),
				_create_card("Standard Shot", 2, "Deal 8 damage (Middle/Back only)", "attack", 8, true, "middle_back"),
				_create_special_card("Take Aim", 0, "Add +1 damage to your next attack", "support", {"take_aim": true}),
				_create_special_card("Take Aim", 0, "Add +1 damage to your next attack", "support", {"take_aim": true}),
				_create_card("Snipe", 3, "Deal 12 damage (Middle/Back only)", "attack", 12, true, "middle_back"),
			]
		# Legacy roles for backwards compatibility
		"tank":
			starting_cards = [
				_create_card("Shield Bash", 2, "Deal 4 damage, gain 6 block", "attack", 4, false, "front", 6),
				_create_card("Defend", 1, "Gain 8 block", "defense", 0, false, "any", 8),
			]
		"medic":
			starting_cards = [
				_create_card("Heal", 2, "Restore 8 HP to any crew", "support", 0, false, "any", 0, 8),
				_create_card("Pistol Shot", 1, "Deal 4 damage", "attack", 4, true, "any"),
			]
		"engineer":
			starting_cards = [
				_create_card("Wrench Strike", 1, "Deal 5 damage", "attack", 5, false, "any"),
				_create_card("Emergency Power", 0, "Gain 2 energy", "support", 0, false, "any", 0, 0, 2),
			]

func _create_card(name: String, cost: int, desc: String, type: String, dmg: int = 0, 
				  ranged: bool = false, pos: String = "any", block_amt: int = 0, 
				  heal_amt: int = 0, energy: int = 0) -> Card:
	var card = Card.new()
	card.card_name = name
	card.energy_cost = cost
	card.description = desc
	card.card_type = type
	card.damage = dmg
	card.is_ranged = ranged
	card.requires_position = pos
	card.block = block_amt
	card.heal = heal_amt
	card.energy_gain = energy
	card.owner_id = crew_id
	return card

func _create_special_card(name: String, cost: int, desc: String, type: String, properties: Dictionary) -> Card:
	var card = Card.new()
	card.card_name = name
	card.energy_cost = cost
	card.description = desc
	card.card_type = type
	card.owner_id = crew_id
	
	# Apply properties from dictionary
	if properties.has("damage"):
		card.damage = properties.damage
	if properties.has("block"):
		card.block = properties.block
	if properties.has("requires_position"):
		card.requires_position = properties.requires_position
	else:
		card.requires_position = "any"
	
	# Special ability flags
	if properties.has("rally"):
		card.rally_effect = true
	if properties.has("heroic_strike"):
		card.move_to_front = true
	if properties.has("protect"):
		card.protect_effect = true
	if properties.has("grenade"):
		card.grenade_effect = true
	if properties.has("take_aim"):
		card.take_aim_effect = true
	if properties.has("taunt"):
		card.taunt_effect = true
	
	return card

func reset_turn():
	"""Reset per-turn status effects"""
	# Damage/defense boosts from Rally wear off
	# (Take Aim lasts until next attack, not until end of turn)

func take_damage(amount: int):
	var damage_taken = max(0, amount - current_block)
	current_block = max(0, current_block - amount)
	
	current_health -= damage_taken
	health_changed.emit(current_health, max_health)
	
	if current_block > 0 and amount > damage_taken:
		print("%s blocked %d damage! Takes %d damage (%d/%d HP, %d block remaining)" % [crew_name, amount - damage_taken, damage_taken, current_health, max_health, current_block])
	else:
		print("%s takes %d damage! (%d/%d HP)" % [crew_name, damage_taken, current_health, max_health])
	
	if current_health <= 0 and is_alive:
		die()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	print("%s healed for %d HP (%d/%d HP)" % [crew_name, amount, current_health, max_health])

func add_block(amount: int):
	current_block += amount
	print("%s gains %d block (total: %d)" % [crew_name, amount, current_block])
	block_changed.emit(current_block)

func reset_block():
	current_block = 0
	block_changed.emit(current_block)

func die():
	is_alive = false
	current_health = 0
	died.emit(self)
	print("%s has died!" % crew_name)

func move_to_position(new_position: String):
	if new_position in ["front", "middle", "back"]:
		position = new_position
		position_changed.emit(new_position)

func get_cards_for_deck() -> Array[Card]:
	var cards = starting_cards.duplicate()
	# Mark cards as dead if crew member is dead
	if not is_alive:
		for card in cards:
			card.is_dead_card = true
	return cards
