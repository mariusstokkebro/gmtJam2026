extends CharacterBody3D
var damage = 0
var lowestVelocity = 0
var wallNormal
var direction
var lastWall
const baseWallrunTime = 0.9
@export var maxHealth = 100
var health = 100
@export var SPEED = 5.0
@export var WallRunSpeed = 7.0
@export var wallRunGravity = 0.7 
@export var wallRunMaxFallSpeed = -1.3
const JUMP_VELOCITY = 4.5
@export var rayCastFront: RayCast3D
@export var rayCastMiddle: RayCast3D
@onready var stateMachine = $StateMachine
@onready var timer = $WallRunTimer

func _physics_process(delta: float) -> void:
		
	print (rayCastMiddle.get_collider())
	apply_gravity(delta)	
	match stateMachine.currentState:
		stateMachine.playerState.IDLE:
			idle_state(delta)
		
		stateMachine.playerState.RUNNING:
			running_state(delta)
			
		stateMachine.playerState.FALLING:
			falling_state(delta)
			
		stateMachine.playerState.WALLRUNNING:
			wallRunning_state(delta)
			
		stateMachine.playerState.JUMPING:
			jumping_state(delta)
			
		stateMachine.playerState.WALLJUMPING:
			wallJumping_state(delta)

	move_and_slide()
func apply_gravity(delta: float) -> void:
	if !is_on_floor():
		velocity += get_gravity() * delta
		
func move_player() -> void:
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForwards", "moveBackwards")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	

func idle_state(delta: float) -> void:
	if !is_on_floor():
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		stateMachine.change_state(stateMachine.playerState.JUMPING)
		return
	
	var input_dir := Input.get_vector("moveLeft", "moveRight", "moveForwards", "moveBackwards")
	if input_dir != Vector2.ZERO:
		stateMachine.change_state(stateMachine.playerState.RUNNING)
		
		
func running_state(delta:float) -> void:
	move_player()
	
	if !is_on_floor():
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		stateMachine.change_state(stateMachine.playerState.JUMPING)
		return
		
	if Input.get_vector("moveLeft", "moveRight", "moveForwards", "moveBackwards") == Vector2.ZERO:
		stateMachine.change_state(stateMachine.playerState.IDLE)
	
func falling_state(delta: float) -> void:
	move_player()
	lowestVelocity = min(lowestVelocity, velocity.y)
	if is_on_floor():
		if lowestVelocity < -3:
			take_damage(abs(lowestVelocity))
		lowestVelocity = 0
		stateMachine.change_state(stateMachine.playerState.IDLE)
		return
		
	if is_on_wall() and rayCastFront.get_collider() and rayCastMiddle.get_collider() == null:
		velocity.y = JUMP_VELOCITY
		stateMachine.change_state(stateMachine.playerState.JUMPING)
		return
		
		 
func wallRunning_state(delta: float) -> void:
	# check jump FIRST, before any early-return can eat the input
	if Input.is_action_just_pressed("jump"):
		var jumpWallDir = wallNormal.cross(Vector3.UP).normalized()
		if jumpWallDir.dot(direction) < 0:
			jumpWallDir = -jumpWallDir

		velocity = wallNormal * 10.0 + jumpWallDir * WallRunSpeed
		velocity.y = JUMP_VELOCITY + 2
		timer.stop()
		stateMachine.change_state(stateMachine.playerState.WALLJUMPING)
		return

	if !is_on_wall():
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return	

	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		lastWall = get_slide_collision(0)
		wallNormal = collision.get_normal()

	var wallDirection = wallNormal.cross(Vector3.UP).normalized()
	if wallDirection.dot(direction) < 0:
		wallDirection = -wallDirection

	var stickForce = 3.0
	velocity.y = max(velocity.y - wallRunGravity * delta, wallRunMaxFallSpeed)
	velocity.x = wallDirection.x * WallRunSpeed - wallNormal.x * stickForce
	velocity.z = wallDirection.z * WallRunSpeed - wallNormal.z * stickForce
	
	
func jumping_state(delta: float) -> void:
	move_player()
	var horizontalSpeed = Vector2(velocity.x, velocity.z).length()
	if is_on_wall() and abs(horizontalSpeed) > 2 and rayCastFront.get_collider() == null:
		timer.start()
		stateMachine.change_state(stateMachine.playerState.WALLRUNNING)
		return 
		
	if is_on_wall() and rayCastFront.get_collider() and rayCastMiddle.get_collider() == null:
		velocity.y = JUMP_VELOCITY
	if velocity.y < 0:
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
	
func wallJumping_state(delta: float) -> void:
	move_player()
	var horizontalSpeed = Vector2(velocity.x, velocity.z).length()
	if is_on_wall() and abs(horizontalSpeed) > 2:
		stateMachine.change_state(stateMachine.playerState.WALLRUNNING)
		return
	if velocity.y < -40:
		print(velocity.y)
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
	if is_on_floor():
		stateMachine.change_state(stateMachine.playerState.IDLE)
	
func take_damage(velocity):
	health = health - velocity * 2
	
func wall_run_time(velocity):
	var time = 0
	time = abs(velocity) * baseWallrunTime
	return time


func _on_wall_run_timer_timeout() -> void:
	if stateMachine.currentState == stateMachine.playerState.WALLRUNNING:
		stateMachine.change_state(stateMachine.playerState.FALLING)
