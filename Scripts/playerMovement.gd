extends CharacterBody3D
var damage = 0
var lowestVelocity = 0
var wallNormal
var direction
var lastWall
var height: int = 999
var sliding = false
var CanRoll = false
var score = 0
const baseWallrunTime = 0.9
@export var maxHealth = 100
var health: int = 100
@export var SPEED = 5.0
@export var WallRunSpeed = 7.0
@export var wallRunGravity = 0.7 
@export var slidingSpeed = 2.0
@export var slidingSlowdown = 0.97
@export var wallRunMaxFallSpeed = -1.3
const JUMP_VELOCITY = 4.5
@export var rayCastFront: RayCast3D
@export var rayCastMiddle: RayCast3D
@export var rayCastDown: RayCast3D
@export var deadUI: Control
@export var winUI: Control
@export var head: Node3D
@export var aimLook: Node
@onready var stateMachine = $StateMachine
@onready var timer = $WallRunTimer


func _ready() -> void:
	health = maxHealth

func _physics_process(delta: float) -> void:
	height = (position.y * 2) + 999
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
			
		stateMachine.playerState.SLIDING:
			sliding_state()
		
		stateMachine.playerState.WALLSLIDE:
			wallslide_state()
			
		stateMachine.playerState.ROLLING:
			rolling_state(delta)
			
		stateMachine.playerState.DEAD:
			dead_state()
		
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
	
	if height <= 0 and health >0:
		winUI.turn_visible()
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
		return
	
	if Input.is_action_just_pressed("sliding") and CanRoll == false:
		rotation_degrees.x = 45
		head.rotation_degrees.x = -45
		velocity *= slidingSpeed
		stateMachine.change_state(stateMachine.playerState.SLIDING)
		return
		
			
func falling_state(delta: float) -> void:
	move_player()
	lowestVelocity = min(lowestVelocity, velocity.y)
	if rayCastDown.get_collider() != null and Input.is_action_just_pressed("sliding"):
		if lowestVelocity < -10:
			lowestVelocity = lowestVelocity * 0.5
			take_damage(abs(lowestVelocity))
		lowestVelocity = 0
		if health <= 0:
			deadUI.turn_visible()
			stateMachine.change_state(stateMachine.playerState.DEAD)
			return
		aimLook.set_camera_control(false)
		stateMachine.change_state(stateMachine.playerState.ROLLING)
		return
	if is_on_floor():
		if lowestVelocity < -5:
			take_damage(abs(lowestVelocity))
		lowestVelocity = 0
		if health <= 0:
			deadUI.turn_visible()
			stateMachine.change_state(stateMachine.playerState.DEAD)
			return
		stateMachine.change_state(stateMachine.playerState.IDLE)
		return
		
	if is_on_wall() and rayCastFront.get_collider() and rayCastMiddle.get_collider() == null:
		velocity.y = JUMP_VELOCITY
		stateMachine.change_state(stateMachine.playerState.JUMPING)
		return
	
	if is_on_wall() and velocity.y > -10:
		velocity.y = 0
		timer.wait_time = 1
		timer.start()
		stateMachine.change_state(stateMachine.playerState.WALLSLIDE)
			
		 
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
		timer.wait_time = 1.5
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
		
func sliding_state() -> void:
	velocity *= slidingSlowdown
	
	if velocity.length() < 2:
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		head.rotation_degrees.x = 0
		stateMachine.change_state(stateMachine.playerState.IDLE)
		return
	if !is_on_floor() and velocity.y < -5:
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		head.rotation_degrees.x = 0
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		head.rotation_degrees.x = 0
		stateMachine.change_state(stateMachine.playerState.JUMPING)
		return
	
func wallslide_state() -> void:
	move_player()
	if sliding == true:
		velocity.y -= 0.001
	else:
		velocity.y = 0
	if !is_on_wall():
		sliding = false
		timer.stop()
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
		
	if velocity.y < -10:
		sliding = false
		timer.stop()
		stateMachine.change_state(stateMachine.playerState.FALLING)
		return
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		stateMachine.change_state(stateMachine.playerState.JUMPING)
		return
	
	
func rolling_state(delta: float) -> void:
	head.rotation_degrees.x += -360.0 * delta
	if head.rotation_degrees.x <= -350:
		head.rotation_degrees.x = 0
		aimLook.set_camera_control(true)
		CanRoll = false
		stateMachine.change_state(stateMachine.playerState.IDLE)
		return
	
		
func dead_state():
	health = 0
	velocity = Vector3(0,0,0)
		
func take_damage(velocity):
	health = health - velocity
	
func wall_run_time(velocity):
	var time = 0
	time = abs(velocity) * baseWallrunTime
	return time


func _on_wall_run_timer_timeout() -> void:
	if stateMachine.currentState == stateMachine.playerState.WALLRUNNING:
		stateMachine.change_state(stateMachine.playerState.FALLING)
	
	if stateMachine.currentState == stateMachine.playerState.WALLSLIDE:
		sliding = true
		
	
