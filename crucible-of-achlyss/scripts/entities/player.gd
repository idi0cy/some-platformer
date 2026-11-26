extends CharacterBody2D

#region | Setting up initial variables

@onready var hitbox = get_node('hitbox')
@onready var hurtbox = get_node('hurtbox')

@onready var coyoteTimer = get_node('coyoteFrames')
@onready var inputBuffer = get_node('inputBuffer')
@onready var slideBuffer = get_node('slideBuffer')

@onready var slideParticles = get_node('slideParticles')

const UP = Vector2(0, -1)
const speed = 300
const jumpPower = 400
const dashSpeed = 1750 + speed

var leftRightWeight = 0
var leftRightValue = 0
var midairMomentum = Vector2(0,0)

const slideThresh = 500
var slideSpeed = 0

var dashing = false
var availableDashes = 1

var sliding = false

#endregion

func _ready() -> void:
	slideParticles.emitting = false

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
	
	handleSlides()
	handleJumps()
	handleLeftToRight()
	handleDashes()
	
	move_and_slide()

func handleLeftToRight():
	if !dashing:
		var directionX = Input.get_axis('a', 'd')
		leftRightWeight = directionX * speed
	if abs(velocity.x) <= abs(leftRightWeight) || leftRightWeight == 0:
		#velocity.x = leftRightWeight
		pass
	else:
		midairMomentum[0] += leftRightWeight * 0.02
	
	if !is_on_floor():
		#midair velocity code goes here
		if !(midairMomentum[0] < 7 && midairMomentum[0] > -7):
			if midairMomentum[0] > 0:
				midairMomentum[0] -= 7
			else:
				midairMomentum[0] += 7
	else:
		midairMomentum = Vector2(0,0)
	
	if !dashing && !sliding:
		velocity.x = midairMomentum[0] + leftRightWeight

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
	slideParticles.emitting = false

func handleSlides():
	
	if Input.is_action_pressed("s") && !sliding && is_on_floor() && abs(velocity.x) > (speed) && !dashing:
		sliding = true
		slideSpeed = velocity.x * 1.15
		slideParticles.emitting = true
	if not (Input.is_action_pressed("s")) && sliding:
		sliding = false
		slideParticles.emitting = false
	if dashing:
		sliding = false
		slideParticles.emitting = false
	
	var directionX = Input.get_axis('a', 'd')
	
	if sliding:
		scale = scale.lerp(Vector2(1, 0.75), 0.1)
	else:
		scale = scale.lerp(Vector2(1, 1), 0.1)
	
	if sliding && directionX != 0:
		velocity.x = slideSpeed
	else:
		pass
		if !(velocity.x > -15 && velocity.x < 15):
			if velocity.x > 0:
				velocity.x -= 15
			else:
				velocity.x += 15
		else:
			sliding = false
			slideParticles.emitting = false


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
			
			midairMomentum += (Vector2(250, 100) * dashDirection)
			oldVelocity = oldVelocity + (Vector2(250,100) * dashDirection)
			
			velocity = oldVelocity
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
