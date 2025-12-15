extends Control

func _ready():
	# Style disabled buttons to look greyed out
	pass

func _on_quick_battle_pressed():
	# Load the combat scene
	get_tree().change_scene_to_file("res://combat_ui.tscn")
