extends CharacterBody2D

#region | Setting up initial variables

@onready var hitbox = get_node('hitbox')
@onready var hurtbox = get_node('hurtbox')

@onready var coyoteTimer = get_node('coyoteFrames')
@onready var inputBuffer = get_node('inputBuffer')
@onready var slideBuffer = get_node('slideBuffer')

const UP = Vector2(0, -1)
const speed = 300
const jumpPower = 400
const dashSpeed = 1750 + speed

const slideThresh = 500

var dashing = false
var availableDashes = 1

var sliding = false

#endregion

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !(is_on_floor()):
		if !dashing:
			velocity += get_gravity() * delta
	else:
		if !dashing:
			availableDashes = 1
	
	#region | Wall jumping and all that
	
	if (is_on_wall() && velocity.y > 0):
		if velocity.y > 150:
			velocity.y = 150
	
	#endregion
	
	handleLeftToRight()
	
	handleSlides()
	handleJumps()
	
	handleDashes()
	
	move_and_slide()

func handleLeftToRight():
	if !dashing:
		var directionX = Input.get_axis('a', 'd')
		velocity.x = directionX * speed
	pass

func handleJumps():
	if is_on_floor():
		coyoteTimer.start()
	if Input.is_action_just_pressed('space'):
		inputBuffer.start()
	
	if !coyoteTimer.is_stopped() && !inputBuffer.is_stopped() && !dashing:
		jump()
		coyoteTimer.stop()
		inputBuffer.stop()
func jump():
	velocity.y -= jumpPower
	sliding = false

func handleSlides():
	if Input.is_action_pressed("s") && !sliding && is_on_floor() && abs(velocity.x) > (speed-1) && !dashing:
		sliding = true
		#print("i've begun the sliding")
	if not (Input.is_action_pressed("s")) && sliding:
		sliding = false
		#print('OH NOOOOOOOOOOOOOOOOOOOO')
	if dashing:
		sliding = false
	
	if sliding == true:
		scale = scale.lerp(Vector2(1, 0.5), 0.2)
	else:
		scale = scale.lerp(Vector2(1, 1), 0.2)

func handleDashes():
	if (!dashing) && (Input.is_action_just_pressed('dash')) && (availableDashes > 0):
		var dashDirection = Input.get_vector("a", "d", "w", "s")
		
		if dashDirection != Vector2(0,0):
			
			availableDashes -= 1
			
			var oldVelocity = velocity
			oldVelocity.y = 0
			velocity = dashDirection * dashSpeed
			dashing = true
			$Sprite2D.modulate = Color(0.0, 1.0, 1.0, 1.0)
			
			await get_tree().create_timer(0.1).timeout
			
			dashing = false
			
			oldVelocity = oldVelocity + (Vector2(250,100) * dashDirection)
			
			velocity = oldVelocity
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
