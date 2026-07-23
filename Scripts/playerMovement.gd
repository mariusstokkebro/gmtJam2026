extends CharacterBody3D
var damage = 0
var elapsedTime = 0
var wallRunTime = 0
var touchedWall = false
var jumped = false
var wallLeft = false
var wallRight = false
var fallen = false
var lowestVelocity = 0
const baseWallrunTime = 0.9
@export var maxHealth = 100
var health
@export var SPEED = 5.0
@export var WallRunSpeed = 7.0
const JUMP_VELOCITY = 4.5
@export var rayCastLeft: RayCast3D
@export var rayCastRight: RayCast3D
func take_damage(velocity):
	health -= velocity * 2
	
func wall_on_side():
	if rayCastLeft.is_colliding():
		wallLeft = true
	if rayCastRight.is_colliding():
		wallRight = true
	
func wall_run_time(velocity):
	var time = 0
	time = abs(velocity) * baseWallrunTime
	return time

func _physics_process(delta: float) -> void:	
	print(lowestVelocity)
	elapsedTime += delta
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		lowestVelocity = velocity.y
	#check for first touch with wall
	if is_on_wall() and not is_on_floor() and not touchedWall:
		touchedWall = true
		wallRunTime = wall_run_time(velocity.x)
		print(wallRunTime)
		elapsedTime = 0
		wall_on_side()
	#jump from wall
	if is_on_wall() and not is_on_floor() and Input.is_action_just_pressed("jump") and jumped == false:
		velocity.y = JUMP_VELOCITY
		jumped = true
	#can wallrun while these are true	
	if touchedWall == true and elapsedTime < wallRunTime and abs(velocity.x) > 0.5 and is_on_wall():
		if Input.is_action_just_pressed("jump") and jumped == false:
			velocity.y = JUMP_VELOCITY
			jumped = true
		else:
			SPEED = WallRunSpeed
			velocity.y = 0
	
	if lowestVelocity < - 3 and is_on_floor():
			take_damage(lowestVelocity)
			fallen = true
			lowestVelocity = 0
	
	if is_on_floor():
		wallRight = false
		wallLeft = false
		touchedWall = false
		jumped = false
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("moveLeft", "moveRight", "moveForwards", "moveBackwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
