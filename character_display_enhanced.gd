extends VBoxContainer
class_name CharacterDisplay

signal character_clicked(character)

var character_data  # CrewMember or Enemy
var is_crew: bool = true
var is_hovered: bool = false

@onready var name_label = $NameLabel
@onready var class_label = $ClassLabel
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
@onready var position_label = $PositionLabel
@onready var block_label = $BlockLabel
@onready var intent_label = $IntentLabel
@onready var sprite = $Sprite

func _ready():
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(character, is_crew_member: bool = true):
	character_data = character
	is_crew = is_crew_member
	
	if is_crew:
		_setup_crew(character as CrewMember)
	else:
		_setup_enemy(character as Enemy)
	
	update_display()

func _setup_crew(crew: CrewMember):
	name_label.text = crew.crew_name
	class_label.text = crew.crew_class
	position_label.text = "Position: %s" % crew.position
	intent_label.visible = false
	
	crew.health_changed.connect(_on_health_changed)
	crew.died.connect(_on_died)
	crew.position_changed.connect(_on_position_changed)
	
	# Try to load animated sprite for this crew role
	_load_crew_sprite(crew.crew_role)
	
	# Color based on role (fallback if no sprite)
	if sprite is ColorRect:
		match crew.crew_role:
			"captain":
				sprite.color = Color(1.0, 0.8, 0.3)  # Gold for captain
			"shield":
				sprite.color = Color(0.5, 0.5, 1.0)  # Blue for shield
			"marksman":
				sprite.color = Color(0.3, 1.0, 0.3)  # Green for marksman
			"fighter":
				sprite.color = Color(1.0, 0.5, 0.5)
			"tank":
				sprite.color = Color(0.5, 0.5, 1.0)
			"medic":
				sprite.color = Color(0.5, 1.0, 0.5)
			"engineer":
				sprite.color = Color(1.0, 0.7, 0.3)

func _setup_enemy(enemy: Enemy):
	name_label.text = enemy.enemy_name
	class_label.visible = false  # Enemies don't show class
	position_label.text = "Position: %s" % enemy.position
	intent_label.visible = true
	
	enemy.health_changed.connect(_on_health_changed)
	enemy.died.connect(_on_died)
	enemy.intent_changed.connect(_on_intent_changed)
	
	# Try to load enemy sprite
	_load_enemy_sprite()
	
	# Fallback color
	if sprite is ColorRect:
		sprite.color = Color(1.0, 0.3, 0.3)  # Red for enemies
	
	_on_intent_changed(enemy.current_intent)

func _load_crew_sprite(role: String):
	# Try to load sprite frames for animated sprite
	var sprite_frames_path = "res://sprites/%s_animations.tres" % role
	if ResourceLoader.exists(sprite_frames_path) and sprite is AnimatedSprite2D:
		sprite.sprite_frames = load(sprite_frames_path)
		sprite.play("idle")
		sprite.centered = true  # Enable centering
		return
	
	# Try to load single sprite texture
	var sprite_path = "res://sprites/%s.png" % role
	if ResourceLoader.exists(sprite_path) and sprite is Sprite2D:
		sprite.texture = load(sprite_path)
		return
	
	# If no sprite found, keep ColorRect with color-coding

func _load_enemy_sprite():
	# Try to load enemy sprite
	var sprite_path = "res://sprites/enemy_pirate.png"
	if ResourceLoader.exists(sprite_path) and sprite is Sprite2D:
		sprite.texture = load(sprite_path)

func update_display():
	if not character_data:
		return
	
	# Update health
	health_label.text = "%d/%d HP" % [character_data.current_health, character_data.max_health]
	health_bar.value = (float(character_data.current_health) / character_data.max_health) * 100
	
	# Update block
	if character_data.get("current_block"):
		if character_data.current_block > 0:
			block_label.text = "🛡 %d" % character_data.current_block
			block_label.visible = true
		else:
			block_label.visible = false
	
	# Gray out if dead
	if not character_data.is_alive:
		modulate = Color(0.5, 0.5, 0.5)
		if sprite is AnimatedSprite2D:
			sprite.play("dead") if sprite.sprite_frames.has_animation("dead") else sprite.stop()

func _on_health_changed(new_health, max_health):
	update_display()
	# Optional: Play hurt animation
	if sprite is AnimatedSprite2D and character_data.is_alive:
		play_animation("hurt")

func _on_died(character):
	update_display()

func _on_intent_changed(intent):
	if not is_crew:
		match intent:
			0:  # ATTACK
				intent_label.text = "Intent: ⚔️ Attack"
			1:  # RANGED_ATTACK
				intent_label.text = "Intent: 🏹 Ranged"
			2:  # DEFEND
				intent_label.text = "Intent: 🛡️ Defend"

func _on_position_changed(new_position):
	position_label.text = "Position: %s" % new_position

func play_animation(anim_name: String):
	"""Play an animation if sprite is AnimatedSprite2D"""
	if sprite is AnimatedSprite2D and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
			await sprite.animation_finished
			if character_data.is_dead:
				sprite.play("idle")

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
		modulate = Color(0.5, 0.5, 0.5)  # Keep dead characters dimmed
