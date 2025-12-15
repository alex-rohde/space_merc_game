extends Resource
class_name Card

# Card definition
@export var card_name: String = "Basic Attack"
@export var energy_cost: int = 1
@export var description: String = "Deal 5 damage"
@export var card_type: String = "attack"  # attack, defense, support, move
@export var requires_position: String = "any"  # front, middle, back, middle_front, middle_back, any
@export var owner_id: int = -1  # Which crew member this card belongs to
@export var is_dead_card: bool = false  # True if crew member is dead

# Card effects
@export var damage: int = 0
@export var block: int = 0
@export var energy_gain: int = 0
@export var heal: int = 0
@export var is_ranged: bool = false
@export var target_count: int = 1  # How many targets this can hit

# Special abilities
@export var move_to_front: bool = false  # Heroic Strike - moves to front if from middle
@export var rally_effect: bool = false  # Rally - boosts hand
@export var protect_effect: bool = false  # Protect - move to front
@export var grenade_effect: bool = false  # Grenade - AOE damage
@export var take_aim_effect: bool = false  # Take Aim - boost next attack
@export var taunt_effect: bool = false  # Taunt - force enemy to attack you

func can_play(crew_member, current_energy: int) -> bool:
	if is_dead_card:
		print("DEBUG: Card %s blocked - is_dead_card" % card_name)
		return false
	if energy_cost > current_energy:
		print("DEBUG: Card %s blocked - need %d energy, have %d" % [card_name, energy_cost, current_energy])
		return false
	
	# Check position requirements
	if requires_position != "any":
		print("DEBUG: Card %s checking position - requires: %s, crew at: %s" % [card_name, requires_position, crew_member.position])
		match requires_position:
			"front":
				if crew_member.position != "front":
					print("DEBUG: Card %s blocked - not in front" % card_name)
					return false
			"middle":
				if crew_member.position != "middle":
					print("DEBUG: Card %s blocked - not in middle" % card_name)
					return false
			"back":
				if crew_member.position != "back":
					print("DEBUG: Card %s blocked - not in back" % card_name)
					return false
			"middle_front":  # Heroic Strike, Protect - can use from middle or front
				if crew_member.position not in ["middle", "front"]:
					print("DEBUG: Card %s blocked - not in middle or front (at %s)" % [card_name, crew_member.position])
					return false
				else:
					print("DEBUG: Card %s OK - in middle_front position (%s)" % [card_name, crew_member.position])
			"middle_back":  # Standard Shot - can use from middle or back
				if crew_member.position not in ["middle", "back"]:
					print("DEBUG: Card %s blocked - not in middle or back" % card_name)
					return false
	
	# Melee attacks can only be used from front row (unless move_to_front ability like Heroic Strike)
	if damage > 0 and not is_ranged and not move_to_front:
		print("DEBUG: Card %s checking melee - damage: %d, ranged: %s, move_to_front: %s, position: %s" % [card_name, damage, is_ranged, move_to_front, crew_member.position])
		if crew_member.position != "front":
			print("DEBUG: Card %s blocked - melee attack not from front" % card_name)
			return false
	
	print("DEBUG: Card %s CAN BE PLAYED" % card_name)
	return true

func get_tooltip() -> String:
	var tooltip = "[b]%s[/b] - Cost: %d Energy\n%s" % [card_name, energy_cost, description]
	if is_dead_card:
		tooltip = "[color=gray][DECEASED - Cannot Play][/color]\n" + tooltip
	return tooltip
