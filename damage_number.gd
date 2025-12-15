extends Label

var velocity := Vector2(0, -50)  # Float upward
var lifetime := 1.0
var elapsed := 0.0

func _ready():
	# Start slightly randomized position
	position.x += randf_range(-10, 10)

func setup(damage_amount: int, is_healing: bool = false, is_blocked: bool = false):
	text = str(damage_amount)
	
	if is_healing:
		# Green for healing
		add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1))
	elif is_blocked:
		# Cyan/Blue for blocked damage
		add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1))
	else:
		# Red for damage
		add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))

func _process(delta):
	elapsed += delta
	
	# Float upward
	position += velocity * delta
	
	# Fade out
	var alpha = 1.0 - (elapsed / lifetime)
	modulate.a = alpha
	
	# Delete when done
	if elapsed >= lifetime:
		queue_free()
