extends VBoxContainer

signal character_clicked(character)

var character_data  # CrewMember or Enemy
var is_crew: bool = true
var is_hovered: bool = false
var previous_health: int = 0  # Track for damage numbers
var previous_block: int = 0  # Track for block indication

# Visual effects
var flash_timer: float = 0.0
var flash_duration: float = 0.15
var is_flashing: bool = false

# Preload damage number scene
const DAMAGE_NUMBER_SCENE = preload("res://damage_number.tscn")

@onready var name_label = $NameLabel
@onready var health_bar = $HealthBarContainer/HealthBar
@onready var health_label = $HealthBarContainer/HealthBar/HealthLabel
@onready var block_label = $BlockLabel
@onready var sprite = $SpriteContainer/Sprite
@onready var sprite_container = $SpriteContainer
@onready var block_glow = $HealthBarContainer/BlockGlow

# Sprite resources for crew roles
const ROLE_SPRITES := {
	"captain":  "res://sprites/marcus_idle.tres",
	"shield":   "res://sprites/gavin_idle.tres",
	"marksman": "res://sprites/harold_idle.tres",
}

# Sprite resources for enemies (by name)
const ENEMY_SPRITES := {
	"Pirate Gunner": "res://sprites/pirate_gunner_idle.tres",
	"Pirate Raider": "res://sprites/pirate_raider_idle.tres",
}

# Death sprites
const DEATH_SPRITE_CREW := "res://sprites/tombstone.tres"
const DEATH_SPRITE_ENEMY := "res://sprites/tombstone_flipped.tres"

func _ready():
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Keep sprite centered when container resizes
	if sprite_container:
		sprite_container.resized.connect(_center_sprite)
	
	_center_sprite()
	
	# Enable processing for flash effect
	set_process(true)

func _process(delta):
	# Handle flash effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			# Return to normal color
			if sprite and sprite.visible:
				sprite.modulate = Color(1.0, 1.0, 1.0) if character_data.is_alive else Color(0.3, 0.3, 0.3)

func setup(character, is_crew_member: bool = true):
	character_data = character
	is_crew = is_crew_member
	previous_health = character.current_health  # Track starting health
	previous_block = character.get("current_block") if character.get("current_block") else 0
	
	if is_crew:
		_setup_crew(character as CrewMember)
	else:
		_setup_enemy(character as Enemy)
	
	update_display()

func _setup_crew(crew: CrewMember):
	name_label.text = crew.crew_name
	
	crew.health_changed.connect(_on_health_changed)
	crew.died.connect(_on_died)
	crew.position_changed.connect(_on_position_changed)
	crew.block_changed.connect(_on_block_changed)
	
	# Load sprite for this crew role (not flipped)
	_load_sprite(ROLE_SPRITES.get(crew.crew_role, ""), false)

func _setup_enemy(enemy: Enemy):
	name_label.text = enemy.enemy_name
	
	enemy.health_changed.connect(_on_health_changed)
	enemy.died.connect(_on_died)
	enemy.block_changed.connect(_on_block_changed)
	
	# Load sprite for this enemy - FLIPPED to face left
	_load_sprite(ENEMY_SPRITES.get(enemy.enemy_name, ""), true)

func _load_sprite(sprite_path: String, flip_horizontal: bool = false):
	"""Load sprite frames from path, or hide sprite if empty"""
	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		sprite.visible = false
		return
	
	if sprite is AnimatedSprite2D:
		sprite.visible = true
		sprite.sprite_frames = load(sprite_path)
		sprite.play("idle")
		sprite.scale = Vector2(0.3, 0.3)
		sprite.centered = true
		sprite.offset = Vector2.ZERO
		sprite.flip_h = flip_horizontal  # Flip horizontally if needed
		_center_sprite()

func _center_sprite():
	"""Center the sprite in the container"""
	if not sprite or not sprite.visible or not sprite_container:
		return
	
	# AnimatedSprite2D must be positioned manually in Control container
	sprite.position = sprite_container.size * 0.5

func flash_damage():
	"""Flash white when taking damage"""
	if sprite and sprite.visible and character_data.is_alive:
		sprite.modulate = Color(2.0, 2.0, 2.0)  # Bright white flash
		is_flashing = true
		flash_timer = flash_duration

func flash_block():
	"""Flash blue when blocking damage"""
	if sprite and sprite.visible and character_data.is_alive:
		sprite.modulate = Color(0.5, 0.5, 2.0)  # Blue flash for block
		is_flashing = true
		flash_timer = flash_duration

func show_damage_number(amount: int, is_healing: bool = false, is_blocked: bool = false):
	"""Spawn a floating damage/heal number"""
	var damage_number = DAMAGE_NUMBER_SCENE.instantiate()
	
	# Add to the root scene, not to this container
	get_tree().root.add_child(damage_number)
	
	# Position in global coordinates above the sprite
	var global_pos = sprite_container.global_position + Vector2(sprite_container.size.x / 2, 20)
	damage_number.global_position = global_pos
	damage_number.setup(amount, is_healing, is_blocked)

func update_display():
	if not character_data:
		return
	
	# Update health with block in same label (using BBCode for color)
	var health_text = "[center]%d/%d HP" % [character_data.current_health, character_data.max_health]
	
	# Add block if present (in cyan/blue)
	var has_block = character_data.get("current_block") and character_data.current_block > 0
	if has_block:
		health_text += " [color=#5DADE2]+%d[/color]" % character_data.current_block
	
	health_text += "[/center]"
	health_label.text = health_text
	
	# Update health bar value and color
	var health_percent = (float(character_data.current_health) / character_data.max_health) * 100
	health_bar.value = health_percent
	
	# Color code the health bar based on percentage
	if health_percent >= 80:
		health_bar.modulate = Color(0.3, 1.0, 0.3)  # Green (80-100%)
	elif health_percent >= 35:
		health_bar.modulate = Color(1.0, 1.0, 0.3)  # Yellow (35-79%)
	else:
		health_bar.modulate = Color(1.0, 0.3, 0.3)  # Red (0-34%)
	
	# Show/hide blue force field glow around entire health bar
	if block_glow:
		block_glow.visible = has_block
	
	# Hide the old separate block label (we're not using it anymore)
	block_label.visible = false
	
	# Gray out if dead (but keep sprite normal brightness)
	if not character_data.is_alive:
		modulate = Color(0.5, 0.5, 0.5)  # Gray out the UI elements
		if sprite and sprite.visible:
			sprite.modulate = Color(1.0, 1.0, 1.0)  # Keep tombstone bright
	else:
		modulate = Color(1.0, 1.0, 1.0)
		if sprite and sprite.visible:
			sprite.modulate = Color(1.0, 1.0, 1.0)

func _on_health_changed(updated_health, updated_max_health):
	# Get current block
	var current_block = character_data.get("current_block") if character_data.get("current_block") else 0
	
	# Calculate health and block changes
	var health_diff = updated_health - previous_health
	var block_diff = previous_block - current_block  # Block went down = damage was blocked
	
	# If block was consumed, show blocked damage
	if block_diff > 0:
		flash_block()
		show_damage_number(block_diff, false, true)  # Blocked damage in blue
	
	# If health went down, show actual damage
	if health_diff < 0:
		flash_damage()
		show_damage_number(abs(health_diff), false, false)  # Real damage in red
	elif health_diff > 0:
		# Healed
		show_damage_number(health_diff, true, false)
	
	previous_health = updated_health
	previous_block = current_block
	update_display()

func _on_died(dead_character):
	update_display()
	name_label.text += " [DEAD]"
	
	# Switch to appropriate tombstone sprite
	var tombstone_path = DEATH_SPRITE_CREW if is_crew else DEATH_SPRITE_ENEMY
	
	if ResourceLoader.exists(tombstone_path) and sprite is AnimatedSprite2D:
		sprite.visible = true
		sprite.sprite_frames = load(tombstone_path)
		sprite.play("dead")
		sprite.scale = Vector2(0.3, 0.3)
		sprite.centered = true
		sprite.flip_h = false  # Don't flip - using correct sprite already
		_center_sprite()

func _on_position_changed(updated_position):
	# Position is now shown by battlefield location, no UI update needed
	pass

func _on_block_changed(updated_block):
	# Update block display immediately
	update_display()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		character_clicked.emit(character_data)

func _on_mouse_entered():
	if is_crew and character_data and character_data.is_alive:
		is_hovered = true
		modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	is_hovered = false
	if not character_data or character_data.is_alive:
		modulate = Color(1.0, 1.0, 1.0)
	else:
		modulate = Color(0.5, 0.5, 0.5)
