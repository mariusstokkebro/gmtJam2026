extends Control


@export var healthText: Label
@export var heightText: Label
@export var character: CharacterBody3D

var health: String = str(99)
var height: String = str(4000)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	health = str(character.health)
	height = str(character.height)
	update_text()
func update_text():
	healthText.text = ("HEALTH " + health)
	heightText.text = ("HEIGHT " + height)
