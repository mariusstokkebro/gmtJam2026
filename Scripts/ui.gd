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
	if character.health < 100 and character.health > 9:
		healthText.text = ("0"+health)
	if character.health == 100:
		healthText.text = (health)
	if character.health < 10:
		healthText.text = ("00"+health)
	if character.height < 100 and character.height > 9:
		heightText.text = ("0"+height)
	if character.height > 100:
		heightText.text = (height)
	if character.height < 10:
		heightText.text = ("00"+height)
	if intTime < 100 and intTime> 9:
		countdownText.text = ("0"+countdown)
	if intTime > 100:
		countdownText.text = (countdown)
	if intTime < 10:
		countdownText.text = ("00"+countdown)
