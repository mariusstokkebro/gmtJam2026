extends Control


@export var healthText: Label
@export var heightText: Label
@export var character: CharacterBody3D
@export var countdownText: Label
var time: float = 100
var intTime: int = 100
var health: String = str(99)
var height: String = str(4000)
var countdown: String = str(100)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	health = str(character.health)
	height = str(character.height)
	time -= delta
	intTime = int(time)
	countdown = str(intTime)
	update_text()
func update_text() -> void:
	healthText.text = ("HEALTH " + health)
	heightText.text = ("HEIGHT " + height)
	countdownText.text = str("FINAL COUNTDOWN " + countdown)
