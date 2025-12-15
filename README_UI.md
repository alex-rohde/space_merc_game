# Space Mercenary Deck Builder - Visual Combat UI

A turn-based deck-building combat system with full visual interface!

## 🎮 How to Play

### Setup
1. Download [Godot Engine 4.2+](https://godotengine.org/download)
2. Extract all files to a folder
3. Open Godot and click "Import"
4. Select `project.godot` from your folder
5. Press F5 to run!

### Controls
- **Click cards** in your hand to select them
- **Click targets** (enemies for attack cards, crew for healing cards)
- **Click "End Turn"** button when done
- Cards that don't need targets play immediately

### Game Flow
1. **Your Turn**
   - You start with 4 energy ⚡
   - Draw 5 cards from your shared deck
   - Play cards by clicking them (costs energy)
   - Click enemy targets for attack cards
   - Click crew for healing cards
   - End turn when ready

2. **Enemy Turn**
   - Enemies show their **Intent** (what they'll do next)
   - They execute their actions
   - Watch the combat log for details

3. **Victory or Defeat**
   - Win: Defeat all enemies
   - Lose: All crew members die

## 🎨 Visual Features

### Card Colors
- 🔴 **Red**: Attack cards
- 🔵 **Blue**: Defense/Block cards  
- 🟢 **Green**: Support/Healing cards
- 🟣 **Purple**: Memorial cards
- ⚫ **Gray**: Dead crew cards (unplayable)

### Card Hover Effects
- Hover over cards to see them lift up
- Dead cards can't be hovered or played
- Cards show energy cost and card type icon

### Character Display
- **Health bars** show current/max HP
- **Block shields** 🛡️ appear when characters have block
- **Position** (Front/Back line) shown below sprite
- **Enemy Intent** shows what they'll do next turn
- Dead characters are grayed out

### Combat Log
- Bottom panel shows all actions
- Auto-scrolls to latest events
- See damage, healing, deaths in real-time

## 💀 Permadeath System

When a crew member dies:
- Their cards stay in deck but become **unplayable** (gray, marked with 💀)
- This weakens your deck until you deal with them
- After combat, you have 2 options:

**Press J**: **Jettison body** - Remove their cards immediately
**Press B**: **Bury with honors** - Get a powerful memorial card

Memorial cards are worth keeping dead weight in your deck!

## 👥 Crew Roles

Each crew member adds different cards to your shared deck:

**Fighter** (Red) - Front line damage dealer
- Slash: 6 damage (front line only)
- Guard: 5 block

**Tank** (Blue) - Front line protector
- Shield Bash: 4 damage + 6 block (front line only)
- Defend: 8 block (x2 cards)

**Sniper** (Yellow) - Back line precision
- Snipe: 10 damage ranged (back line only, x2 cards)
- Take Cover: 4 block

**Medic** (Green) - Support healer
- Heal: 8 HP to any crew
- Bandage: 4 HP
- Pistol Shot: 4 damage ranged

**Engineer** (Orange) - Resource generation
- Wrench Strike: 5 damage
- Emergency Power: Gain 2 energy (FREE!)
- Repair: 6 block

## 🎯 Formation System

**Front Line**
- Takes melee attacks first
- Protects back line from melee
- Required for melee attack cards

**Back Line**  
- Can be hit by ranged attacks
- Reduced accuracy if protected by front line
- Required for sniper cards

**Movement**: Click crew (feature to be added) or use move cards

## 🧠 Enemy AI

Enemies telegraph their next action:
- **Attack X**: Will deal X melee damage to front line
- **Ranged X**: Will shoot for X damage (can hit back line)
- **Defend X**: Will gain X block

Use this info to plan your defense!

## 📁 File Structure

```
card.gd              - Card resource definition
card_ui.gd           - Visual card display with hover effects
card_ui.tscn         - Card UI scene
crew_member.gd       - Crew members with roles and cards
character_display.gd - Visual character display
character_display.tscn - Character display scene
enemy.gd             - Enemy AI with intent system
combat_manager.gd    - Core combat logic
combat_ui.gd         - Main UI controller
combat_ui.tscn       - Main UI layout
project.godot        - Godot project file
```

## 🔧 Customization

### Add New Cards
Edit `crew_member.gd` in the `_initialize_starting_cards()` function:

```gdscript
"hacker":
    starting_cards = [
        _create_card("System Breach", 2, "Deal 8 damage", "attack", 8, true, "back"),
    ]
```

### Change Energy Per Turn
Edit `combat_manager.gd`:
```gdscript
var max_energy: int = 5  # Changed from 4 to 5
```

### Adjust Card Costs/Damage
Edit the card creation in `crew_member.gd`:
```gdscript
_create_card("Slash", 2, "Deal 10 damage", "attack", 10, false, "front"),
```

## 🚀 What's Next?

### Immediate Improvements
- [ ] Click to move crew between positions
- [ ] Better visual feedback when playing cards
- [ ] Sound effects for actions
- [ ] Particle effects for damage/healing
- [ ] Animated card drawing

### Next Features
- [ ] Map/travel between encounters
- [ ] Shop to buy cards and hire crew
- [ ] Crew leveling and skill trees
- [ ] More enemy types
- [ ] Boss battles
- [ ] Status effects (poison, stun, buffs)

### Roguelike Structure
- [ ] Multiple encounters per run
- [ ] Difficulty scaling
- [ ] Meta-progression between runs
- [ ] Unlockable content
- [ ] Faction reputation system

## 🎯 Tips for Playing

1. **Energy management is key** - Don't waste energy on low-value plays
2. **Watch enemy intents** - Block big attacks, push damage when they defend
3. **Protect your backline** - Keep a front line alive to protect snipers/medics
4. **Dead cards hurt** - Decide quickly whether to jettison or bury
5. **Engineer's Emergency Power** - Free energy is always good!
6. **Combo attacks** - Use block to survive, then counter-attack next turn

## 🐛 Known Issues

- No manual crew repositioning yet (coming soon)
- Enemy targeting is simplified
- No status effects or buffs yet
- Memorial cards need special effect implementation

## 💡 Development Notes

Built with Godot 4.2+ using:
- GDScript for all game logic
- Built-in UI nodes for interface
- Signal-based event system
- Resource-based card system

The architecture separates:
- **Game logic** (combat_manager.gd) - No UI dependencies
- **Visual layer** (combat_ui.gd) - Pure presentation
- **Data** (card.gd, crew_member.gd) - Reusable resources

This makes it easy to:
- Add new card types
- Create new crew roles
- Expand enemy varieties
- Build new UI layouts

---

**Ready to play?** Import the project and press F5!

**Want to expand?** The codebase is ready for:
- Map system
- Shop mechanics
- Progression systems
- More content!
