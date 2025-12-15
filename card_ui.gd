extends PanelContainer
class_name CardUI

signal card_clicked(card_ui: CardUI)

var card_data: Card
var card_index: int = -1

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var cost_label = $MarginContainer/VBoxContainer/TopBar/CostLabel  
@onready var type_label = $MarginContainer/VBoxContainer/TopBar/TypeLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel

var is_hovered: bool = false
var base_y_position: float = 0

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# Set minimum size
	custom_minimum_size = Vector2(120, 160)

func setup(card: Card, index: int):
	card_data = card
	card_index = index
	
	if card_data:
		name_label.text = card_data.card_name
		cost_label.text = "⚡%d" % card_data.energy_cost
		type_label.text = _get_type_icon()
		description_label.text = card_data.description
		
		_update_visual_style()
		
		# Store base position after next frame
		await get_tree().process_frame
		base_y_position = position.y

func _get_type_icon() -> String:
	if card_data.is_dead_card:
		return "💀"
	
	match card_data.card_type:
		"attack":
			return "⚔️"
		"defense":
			return "🛡️"
		"support":
			return "✨"
		"move":
			return "🏃"
		"memorial":
			return "🕯️"
		_:
			return "❓"

func _update_visual_style():
	if not card_data:
		return
	
	var style = StyleBoxFlat.new()
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	if card_data.is_dead_card:
		# Dead cards are grayed out
		style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
		style.border_color = Color(0.4, 0.4, 0.4)
		modulate.a = 0.6
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		# Color by card type
		match card_data.card_type:
			"attack":
				style.bg_color = Color(0.7, 0.2, 0.2, 0.95)
				style.border_color = Color(1.0, 0.3, 0.3)
			"defense":
				style.bg_color = Color(0.2, 0.4, 0.7, 0.95)
				style.border_color = Color(0.3, 0.5, 1.0)
			"support":
				style.bg_color = Color(0.3, 0.6, 0.3, 0.95)
				style.border_color = Color(0.4, 0.8, 0.4)
			"memorial":
				style.bg_color = Color(0.5, 0.4, 0.7, 0.95)
				style.border_color = Color(0.7, 0.6, 1.0)
			_:
				style.bg_color = Color(0.4, 0.4, 0.4, 0.95)
				style.border_color = Color(0.6, 0.6, 0.6)
		
		mouse_filter = Control.MOUSE_FILTER_STOP
	
	add_theme_stylebox_override("panel", style)

func _on_mouse_entered():
	if card_data and not card_data.is_dead_card:
		is_hovered = true
		# Lift card up when hovering
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position:y", base_y_position - 40, 0.15)
		tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)

func _on_mouse_exited():
	if card_data and not card_data.is_dead_card:
		is_hovered = false
		# Return to base position
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position:y", base_y_position, 0.15)
		tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if card_data and not card_data.is_dead_card:
				card_clicked.emit(self)
