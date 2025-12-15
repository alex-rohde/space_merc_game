extends Node
class_name CombatManager

signal combat_ended(victory: bool)
signal turn_started(turn_number: int)
signal energy_changed(current: int, max: int)
signal hand_updated(cards: Array)
signal crew_died(crew_member: CrewMember)
signal position_updated()  # Emitted when crew positions change
signal deck_updated(draw_count: int, discard_count: int)

# Combat state
enum CombatState { PLAYER_TURN, ENEMY_TURN, COMBAT_END }
var current_state: CombatState = CombatState.PLAYER_TURN

# Turn tracking
var turn_number: int = 0
var max_energy: int = 4
var current_energy: int = 4

# Deck management
var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var hand: Array[Card] = []
var hand_size: int = 5

# Combatants
var player_crew: Array[CrewMember] = []
var enemies: Array[Enemy] = []

# Memorial system
var deceased_crew: Array = []  # Stores {crew_member, cards} for burial later

func _ready():
	print("=== COMBAT PROTOTYPE ===")

func setup_combat(crew: Array[CrewMember], enemy_list: Array[Enemy]):
	player_crew = crew
	enemies = enemy_list
	
	# Manually initialize cards for all crew (in case _ready hasn't fired yet)
	for crew_member in player_crew:
		if crew_member.starting_cards.is_empty():
			crew_member._initialize_starting_cards()
	
	# Connect crew death signals
	for crew_member in player_crew:
		crew_member.died.connect(_on_crew_died)
	
	# Build initial deck from all crew members
	_build_deck()
	
	# Start combat
	start_turn()

func _build_deck():
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	
	# Collect cards from all crew members (alive or dead)
	for crew_member in player_crew:
		var cards = crew_member.get_cards_for_deck()
		draw_pile.append_array(cards)
	
	# Shuffle deck
	draw_pile.shuffle()
	print("Deck built with %d cards" % draw_pile.size())
	deck_updated.emit(draw_pile.size(), discard_pile.size())

func start_turn():
	if _check_combat_end():
		return
	
	turn_number += 1
	current_state = CombatState.PLAYER_TURN
	
	# Reset energy
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
	
	# Reset crew block
	for crew_member in player_crew:
		crew_member.reset_block()
	
	# Draw cards
	draw_cards(hand_size)
	
	turn_started.emit(turn_number)
	print("\n=== TURN %d - PLAYER PHASE ===" % turn_number)
	print("Energy: %d/%d" % [current_energy, max_energy])
	_print_hand()

func draw_cards(count: int):
	for i in count:
		if draw_pile.is_empty():
			# Reshuffle discard into draw pile
			if discard_pile.is_empty():
				print("No more cards to draw!")
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
			print("🔄 Reshuffled discard pile into draw pile (%d cards)" % draw_pile.size())
		
		var card = draw_pile.pop_front()
		hand.append(card)
	
	hand_updated.emit(hand)
	deck_updated.emit(draw_pile.size(), discard_pile.size())

func play_card(card_index: int, target = null):
	if current_state != CombatState.PLAYER_TURN:
		print("Not player turn!")
		return false
	
	if card_index < 0 or card_index >= hand.size():
		print("Invalid card index!")
		return false
	
	var card = hand[card_index]
	
	# Find crew member who owns this card
	var owner = _find_crew_by_id(card.owner_id)
	if owner == null:
		print("Cannot find card owner!")
		return false
	
	# Check if card can be played
	if not card.can_play(owner, current_energy):
		if card.is_dead_card:
			print("Cannot play card from deceased crew member: %s" % owner.crew_name)
		else:
			print("Cannot play card - insufficient energy or wrong position")
		return false
	
	# Pay energy cost
	current_energy -= card.energy_cost
	energy_changed.emit(current_energy, max_energy)
	
	# Execute card effect - returns false if invalid
	if not _execute_card(card, owner, target):
		# Execution failed, refund energy
		current_energy += card.energy_cost
		energy_changed.emit(current_energy, max_energy)
		return false
	
	# Move card to discard (only if execution succeeded)
	hand.remove_at(card_index)
	discard_pile.append(card)
	hand_updated.emit(hand)
	deck_updated.emit(draw_pile.size(), discard_pile.size())
	
	return true

func _execute_card(card: Card, owner: CrewMember, target) -> bool:
	print("\n%s plays [%s]" % [owner.crew_name, card.card_name])
	
	# SPECIAL ABILITIES
	
	# Rally - boost hand for this turn
	if card.rally_effect:
		for hand_card in hand:
			if not hand_card.is_dead_card and hand_card.owner_id != owner.crew_id:
				hand_card.damage += 1
				hand_card.block += 1
		print("Rally! All cards in hand gain +1 damage and +1 block this turn")
		hand_updated.emit(hand)
	
	# Heroic Strike - move to front if from middle
	if card.move_to_front and owner.position == "middle":
		# Find first available slot in front
		var front_crew = player_crew.filter(func(c): return c.position == "front" and c.is_alive)
		var occupied_slots = front_crew.map(func(c): return c.slot_index)
		
		var target_slot = 0
		for i in range(3):
			if not i in occupied_slots:
				target_slot = i
				break
		
		owner.move_to_position("front")
		owner.slot_index = target_slot
		print("%s charges to the front line! (slot %d)" % [owner.crew_name, target_slot])
		position_updated.emit()
	
	# Protect - move to front and add block to all front crew
	if card.protect_effect:
		if owner.position != "front":
			# Find first available slot in front position
			var front_crew = player_crew.filter(func(c): return c.position == "front" and c.is_alive)
			var occupied_slots = front_crew.map(func(c): return c.slot_index)
			
			# Find first empty slot (0-2)
			var target_slot = 0
			for i in range(3):
				if not i in occupied_slots:
					target_slot = i
					break
			
			owner.move_to_position("front")
			owner.slot_index = target_slot
			print("%s moves to protect the front line! (slot %d)" % [owner.crew_name, target_slot])
			position_updated.emit()
		
		# Add block to all crew in front position
		var front_crew = player_crew.filter(func(c): return c.position == "front" and c.is_alive)
		for crew_member in front_crew:
			crew_member.add_block(card.block)
			print("  %s gains %d block" % [crew_member.crew_name, card.block])
	
	# Take Aim - boost next attack
	if card.take_aim_effect:
		owner.damage_boost += 1
		print("%s takes careful aim (+1 damage to next attack)" % owner.crew_name)
	
	# Taunt - force enemy to attack you
	if card.taunt_effect:
		if target and target is Enemy:
			target.taunted_by = owner
			print("🛡 %s taunts %s! It must attack them next turn." % [owner.crew_name, target.enemy_name])
	
	# Grenade - AOE damage (handled in damage section)
	
	# Damage (skip for protect_effect cards - they don't deal damage)
	if not card.protect_effect and card.damage > 0:
		var actual_damage = card.damage + owner.damage_boost
		if card.grenade_effect:
			# Grenade: damage target and adjacent enemies in same position
			if target and target is Enemy:
				var targets = [target]
				# Find adjacent enemies in same position
				var same_pos_enemies = enemies.filter(func(e): return e.is_alive and e.position == target.position and e != target)
				targets.append_array(same_pos_enemies)
				
				print("💥 GRENADE! %s throws grenade at %s (hitting %d targets for %d damage each)" % [owner.crew_name, target.enemy_name, targets.size(), actual_damage])
				for t in targets:
					t.take_damage(actual_damage, false)
		else:
			# Normal damage
			if target == null:
				# Auto-target: prefer front line enemies for melee, any for ranged
				var alive_enemies = enemies.filter(func(e): return e.is_alive)
				if not alive_enemies.is_empty():
					if card.is_ranged:
						target = alive_enemies.pick_random()
					else:
						# Melee: can only target nearest populated row
						# First check which is the nearest populated enemy row
						var front_enemies = alive_enemies.filter(func(e): return e.position == "front")
						if not front_enemies.is_empty():
							target = front_enemies.pick_random()
						else:
							var middle_enemies = alive_enemies.filter(func(e): return e.position == "middle")
							if not middle_enemies.is_empty():
								target = middle_enemies.pick_random()
							else:
								target = alive_enemies.pick_random()
			
			# Check if melee attack is valid (for both auto and manual targeting)
			if target and target is Enemy and not card.is_ranged:
				# Melee restrictions:
				# 1. Attacker must be in front row (unless it's a move+attack like Heroic Strike)
				# 2. Can only target nearest populated enemy row
				var can_melee = false
				
				if owner.position == "front":
					# Front row can melee
					can_melee = true
				elif card.move_to_front:
					# Heroic Strike moves to front, so it can melee from middle
					can_melee = true
				else:
					# Not in front and doesn't move to front
					can_melee = false
					print("❌ %s cannot melee from %s position!" % [owner.crew_name, owner.position])
				
				if can_melee:
					# Check if targeting the nearest enemy row
					var front_enemies = enemies.filter(func(e): return e.is_alive and e.position == "front")
					var middle_enemies = enemies.filter(func(e): return e.is_alive and e.position == "middle")
					
					# Can only target front if front exists, otherwise middle
					if not front_enemies.is_empty() and target.position != "front":
						print("❌ Front row enemies block access to %s!" % target.position)
						can_melee = false
					elif front_enemies.is_empty() and not middle_enemies.is_empty() and target.position == "back":
						print("❌ Middle row enemies block access to back row!")
						can_melee = false
				
				if not can_melee:
					# Invalid target - card execution failed
					return false
			
			if target and target is Enemy:
				var attack_type = "🏹 ranged attack" if card.is_ranged else "⚔️ melee attack"
				print("%s %s %s for %d damage" % [owner.crew_name, attack_type, target.enemy_name, actual_damage])
				target.take_damage(actual_damage, card.is_ranged)
	
	# Consume damage boost after attack
		if owner.damage_boost > 0:
			owner.damage_boost = 0
			print("(Aim bonus consumed)")
	
	# Block (skip for protect_effect - it handles block for all front crew)
	if not card.protect_effect:
		var actual_block = card.block + owner.defense_boost
		if actual_block > 0:
			owner.add_block(actual_block)
			print("%s gains %d block" % [owner.crew_name, actual_block])
	
	# Heal
	if card.heal > 0:
		if target == null:
			target = owner
		if target is CrewMember:
			target.heal(card.heal)
			print("%s heals %s for %d HP" % [owner.crew_name, target.crew_name, card.heal])
	
	# Energy gain
	if card.energy_gain > 0:
		current_energy = min(current_energy + card.energy_gain, max_energy)
		energy_changed.emit(current_energy, max_energy)
		print("Gained %d energy" % card.energy_gain)
	
	# Card executed successfully
	return true

func move_crew(crew_member: CrewMember, new_position: String, energy_cost: int = 1):
	if current_state != CombatState.PLAYER_TURN:
		return false
	
	if current_energy < energy_cost:
		print("Not enough energy to move!")
		return false
	
	if crew_member.position == new_position:
		print("Already in that position!")
		return false
	
	# Check if move is to adjacent position only
	var valid_move = false
	match crew_member.position:
		"front":
			valid_move = (new_position == "middle")
		"middle":
			valid_move = (new_position in ["front", "back"])
		"back":
			valid_move = (new_position == "middle")
	
	if not valid_move:
		print("Can only move to adjacent positions! (front<->middle<->back)")
		return false
	
	current_energy -= energy_cost
	crew_member.move_to_position(new_position)
	energy_changed.emit(current_energy, max_energy)
	print("%s moved from %s to %s" % [crew_member.crew_name, crew_member.position, new_position])
	return true

func end_turn():
	if current_state != CombatState.PLAYER_TURN:
		return
	
	print("\n=== ENEMY PHASE ===")
	current_state = CombatState.ENEMY_TURN
	
	# Discard remaining hand
	discard_pile.append_array(hand)
	hand.clear()
	hand_updated.emit(hand)
	deck_updated.emit(draw_pile.size(), discard_pile.size())
	
	# Reset block for ALL combatants (crew and enemies)
	for crew_member in player_crew:
		crew_member.reset_block()
	for enemy in enemies:
		enemy.reset_block()
	
	# Enemies take turns
	for enemy in enemies:
		if enemy.is_alive:
			enemy.take_turn(player_crew, enemies)
			await get_tree().create_timer(0.5).timeout  # Small delay for readability
	
	# Update display after enemy movements
	position_updated.emit()
	
	# Check if combat ended
	if _check_combat_end():
		return
	
	# Start next turn
	start_turn()

func _check_combat_end() -> bool:
	var alive_crew = player_crew.filter(func(c): return c.is_alive)
	var alive_enemies = enemies.filter(func(e): return e.is_alive)
	
	if alive_crew.is_empty():
		current_state = CombatState.COMBAT_END
		print("\n=== DEFEAT ===")
		combat_ended.emit(false)
		return true
	
	if alive_enemies.is_empty():
		current_state = CombatState.COMBAT_END
		print("\n=== VICTORY ===")
		combat_ended.emit(true)
		return true
	
	return false

func _find_crew_by_id(id: int) -> CrewMember:
	for crew in player_crew:
		if crew.crew_id == id:
			return crew
	return null

func _on_crew_died(crew_member: CrewMember):
	print("\n!!! %s HAS FALLEN !!!" % crew_member.crew_name)
	
	# Store for potential burial
	deceased_crew.append({
		"crew": crew_member,
		"cards": crew_member.get_cards_for_deck()
	})
	
	crew_died.emit(crew_member)
	
	# Their cards remain in deck but become unplayable
	# This happens automatically via the is_dead_card flag

func jettison_body(crew_member: CrewMember):
	# Remove dead cards from deck permanently
	print("Jettisoning %s's body into space..." % crew_member.crew_name)
	
	# Remove from all piles
	draw_pile = draw_pile.filter(func(c): return c.owner_id != crew_member.crew_id)
	discard_pile = discard_pile.filter(func(c): return c.owner_id != crew_member.crew_id)
	hand = hand.filter(func(c): return c.owner_id != crew_member.crew_id)
	
	# Remove from deceased list
	deceased_crew = deceased_crew.filter(func(d): return d.crew != crew_member)
	
	hand_updated.emit(hand)
	print("Deck cleaned of %s's cards" % crew_member.crew_name)

func bury_with_honors(crew_member: CrewMember) -> Card:
	print("Burying %s with full honors..." % crew_member.crew_name)
	
	# Create memorial card
	var memorial = Card.new()
	memorial.card_name = "Memory of %s" % crew_member.crew_name
	memorial.energy_cost = 0
	memorial.description = "In loving memory. Draw 2 cards."
	memorial.card_type = "memorial"
	memorial.requires_position = "any"
	# Add special memorial effect (would need custom handling)
	
	# Remove dead cards
	jettison_body(crew_member)
	
	# Add memorial to deck
	draw_pile.append(memorial)
	
	print("Memorial card added to deck")
	return memorial

func _print_hand():
	print("\nHand:")
	for i in hand.size():
		var card = hand[i]
		var status = ""
		if card.is_dead_card:
			status = " [DEAD - UNPLAYABLE]"
		print("  %d. [%d energy] %s%s" % [i, card.energy_cost, card.card_name, status])
