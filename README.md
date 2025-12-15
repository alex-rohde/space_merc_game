# Space Mercenary Deck Builder - Combat Prototype

A turn-based deck-building combat system for a space mercenary roguelike game.

## Features Implemented

### Core Combat Mechanics
- **Energy System**: 4 energy per turn, cards cost energy to play
- **Turn-based Combat**: Player phase → Enemy phase → Repeat
- **Formation System**: Front line and back line positioning
- **Card Types**: Attack, Defense, Support, Movement
- **Permadeath**: When crew dies, their cards become unplayable but stay in deck

### Crew Roles
Each crew member contributes different cards to the shared deck:

- **Fighter**: Balanced melee damage and defense (front line)
- **Tank**: High block, protective abilities (front line)
- **Sniper**: High damage ranged attacks (back line required)
- **Medic**: Healing and support (any position)
- **Engineer**: Energy generation and repairs (any position)

### Enemy AI
- Enemies telegraph their next action (Intent system)
- Can perform melee attacks, ranged attacks, or defend
- Simple targeting: melee targets front line first, ranged can hit anyone
- Ranged attacks have reduced accuracy against protected back line

### Death & Memorial System
When crew dies:
1. Their cards remain in deck but become unplayable (dead weight)
2. **Option 1**: Jettison body - immediately remove cards from deck
3. **Option 2**: Bury with honors at a planet - receive powerful memorial card

## Setup Instructions

### Prerequisites
- Download [Godot Engine 4.2+](https://godotengine.org/download)

### Installation
1. Extract all `.gd` files and `.tscn` file to a folder
2. Open Godot Engine
3. Click "Import" and select the `project.godot` file
4. Click "Import & Edit"
5. Press F5 or click the Play button to run

## How to Use

### Auto-Demo Mode (Default)
The prototype automatically plays through a combat encounter when you run it. Watch the console output to see:
- Cards being played
- Damage dealt
- Enemies taking turns
- Combat resolution

### Manual Testing Controls
To test manually, comment out the `_run_demo_combat()` call in `test_combat.gd`:

```gdscript
# _run_demo_combat()  # Comment this line
```

Then use these controls:
- **1-5 keys**: Play card at that position in hand
- **Spacebar**: End turn

## File Structure

```
card.gd              - Card resource definition
crew_member.gd       - Crew member class with health, position, cards
enemy.gd             - Enemy class with AI and intent system
combat_manager.gd    - Main combat controller (deck, turns, energy)
test_combat.gd       - Test scene that runs combat demo
test_combat.tscn     - Godot scene file
project.godot        - Godot project configuration
```

## Combat Flow

1. **Turn Start**
   - Reset energy to 4
   - Reset all block values
   - Draw 5 cards

2. **Player Phase**
   - Play cards (costs energy)
   - Move crew members (costs energy)
   - Cards execute immediately
   - Can end turn early

3. **Enemy Phase**
   - Each enemy executes their intent
   - Enemies reveal next turn's intent

4. **Check Victory/Defeat**
   - Victory: All enemies defeated
   - Defeat: All crew members dead

## Key Design Patterns

### Dead Card Mechanic
```gdscript
# When crew dies, their cards become unplayable
if not is_alive:
    for card in cards:
        card.is_dead_card = true

# Cards check if they can be played
func can_play(crew_member, current_energy):
    if is_dead_card:
        return false
    # ... other checks
```

### Deck Building
```gdscript
# All crew contribute to one shared deck
for crew_member in player_crew:
    var cards = crew_member.get_cards_for_deck()
    draw_pile.append_array(cards)
```

### Formation Targeting
```gdscript
# Melee must target front line first
var targets = enemies.filter(func(e): return e.is_alive and e.position == "front")
if targets.is_empty():
    # Only if no front line, can target back
    targets = enemies.filter(func(e): return e.is_alive and e.position == "back")
```

## Next Steps to Build Full Game

### Phase 1: UI Layer
- Visual card display with hover tooltips
- Energy bar indicator
- Health bars for crew and enemies
- Position indicators (front/back line)
- Click-to-play interface

### Phase 2: Expand Combat
- More card types and effects
- Status effects (poison, stun, buff, debuff)
- Multi-target attacks
- Synergies between crew members
- More enemy types with unique behaviors

### Phase 3: Meta Systems
- Map/travel between encounters
- Shop system (buy cards, recruit crew)
- Ship upgrades that modify deck
- Leveling system with skill trees
- Loot and rewards

### Phase 4: Roguelike Loop
- Multiple encounters per run
- Difficulty scaling
- Run-based progression
- Unlockable content
- Meta-progression between runs

### Phase 5: Faction System
- Reputation tracking
- Faction-specific encounters
- Dynamic events based on relationships
- Faction quests and bounties

## Customization Examples

### Adding a New Crew Role
Edit `crew_member.gd`, add to `_initialize_starting_cards()`:

```gdscript
"hacker":
    starting_cards = [
        _create_card("System Breach", 2, "Deal 8 damage to all enemies", "attack", 8, true, "back"),
        _create_card("Firewall", 1, "Gain 6 block", "defense", 0, false, "any", 6),
    ]
```

### Adding a New Card Effect
Edit `combat_manager.gd`, expand `_execute_card()`:

```gdscript
# Add card property in card.gd:
@export var draw_cards: int = 0

# Execute in combat_manager.gd:
if card.draw_cards > 0:
    draw_cards(card.draw_cards)
```

### Tweaking Balance
Adjust values in:
- Energy per turn: `max_energy` in `combat_manager.gd`
- Hand size: `hand_size` in `combat_manager.gd`
- Card costs/damage: Card creation in `crew_member.gd`
- Crew health: `max_health` in crew creation

## Console Output Example

```
=== COMBAT PROTOTYPE ===
Deck built with 9 cards
=== TURN 1 - PLAYER PHASE ===
Energy: 4/4

Hand:
  0. [1 energy] Slash
  1. [2 energy] Snipe
  2. [1 energy] Guard
  3. [0 energy] Emergency Power
  4. [2 energy] Shield Bash

Marcus plays [Slash]
Pirate Gunner takes 6 damage! (6/12 HP)

=== ENEMY PHASE ===
Pirate Gunner attacks Marcus for 5 damage!
Pirate Raider intends to: DEFEND (+6)
```

## Known Limitations (Prototype)

- No visual UI, console-only
- Simple AI (random action selection)
- Auto-targeting (no manual target selection in demo)
- No status effects or buffs
- No card upgrading or removal
- Memorial cards not fully implemented with special effects

## Contributing Ideas

This prototype is the foundation. You can extend it with:
- Relic/artifact system (passive bonuses)
- Environmental hazards in combat
- Combo system (play certain cards in sequence for bonus)
- Crew relationships (synergy bonuses)
- Ship weapons that act as extra "cards"
- Boss encounters with multiple phases

---

**Ready to expand?** Start by building the UI layer so you can see cards visually and click to play them!
