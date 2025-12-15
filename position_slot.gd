extends PanelContainer
class_name PositionSlot

signal slot_clicked(position_name: String, is_crew_side: bool, slot_index: int)

var position_name: String = "front"  # front, middle, back
var is_crew_side: bool = true
var slot_index: int = 0  # Which slot in this position (0-3)
var is_highlighted: bool = false
var is_hovered: bool = false

@onready var container = $Container

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	_update_visual()

func setup(pos_name: String, crew_side: bool, index: int = 0):
	position_name = pos_name
	is_crew_side = crew_side
	slot_index = index
	_update_visual()

func set_highlighted(highlighted: bool):
	is_highlighted = highlighted
	_update_visual()

func _update_visual():
	var style = StyleBoxFlat.new()
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	if is_highlighted:
		# Highlighted - valid move target
		style.bg_color = Color(0.3, 0.6, 1.0, 0.3)
		style.border_color = Color(0.5, 0.8, 1.0, 0.8)
	elif is_hovered:
		# Hovered
		style.bg_color = Color(0.3, 0.3, 0.4, 0.3)
		style.border_color = Color(0.5, 0.5, 0.6, 0.6)
	else:
		# Default - empty slot outline
		style.bg_color = Color(0.2, 0.2, 0.25, 0.2)
		style.border_color = Color(0.4, 0.4, 0.45, 0.4)
	
	add_theme_stylebox_override("panel", style)

func _on_mouse_entered():
	if is_highlighted:
		is_hovered = true
		_update_visual()

func _on_mouse_exited():
	is_hovered = false
	_update_visual()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_highlighted:
				slot_clicked.emit(position_name, is_crew_side, slot_index)

func get_container():
	return container
