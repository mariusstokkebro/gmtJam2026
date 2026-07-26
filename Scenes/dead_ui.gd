extends Control

@export var retryButton: Button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	retryButton.pressed.connect(_button_pressed)

func turn_visible():
	visible = true

func _button_pressed():
	get_tree().reload_current_scene()
