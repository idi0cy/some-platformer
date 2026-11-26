extends CharacterBody2D

#region | Setting up initial variables

@onready var hitbox = get_node('hitbox')
@onready var hurtbox = get_node('hurtbox')

@onready var coyoteTimer = get_node('coyoteFrames')
@onready var inputBuffer = get_node('inputBuffer')

@onready var slideParticles = get_node('slideParticles')

#const UP = Vector2(0, -1)
const speed = 250
const jumpPower = 350
const dashSpeed = 1750 + speed

var leftRightWeight = 0
var leftRightValue = 0
var midairMomentum = Vector2(0,0)

const slideThresh = 500
var slideSpeed = 0
var sliding = false

var dashing = false
var availableDashes = 1

var clinging = false
var clingSpeedWeight = 0
var clingEntrySpeed = 0

#endregion

func _ready() -> void:
	slideParticles.emitting = false

func _process(delta: float) -> void:
	if !(is_on_floor()):
		if !dashing && !clinging:
			velocity += get_gravity() * delta
	else:
		if !dashing:
			availableDashes = 1
	
	handleSlides()
	handleJumps()
	handleLeftToRight()
	handleDashes()
	handleWallMechanics()
	
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
		if !(midairMomentum[0] < 10 && midairMomentum[0] > -10):
			if midairMomentum[0] > 0:
				midairMomentum[0] -= 10
			else:
				midairMomentum[0] += 10
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
func shortJump():
	velocity.y -= 250
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
	
	if sliding:
		scale = scale.lerp(Vector2(1, 0.75), 0.1)
	else:
		scale = scale.lerp(Vector2(1, 1), 0.1)
	
	var directionX = Input.get_axis('a', 'd')
	
	if (Input.is_action_pressed('a') || Input.is_action_pressed('d')) && directionX == 0 && sliding:
		shortJump()
	
	if sliding && directionX != 0:
		velocity.x = slideSpeed
	elif sliding && !(Input.is_action_pressed('a') || Input.is_action_pressed('d')):
		if !(velocity.x > -15 && velocity.x < 15):
			if velocity.x > 0:
				velocity.x -= 15
			else:
				velocity.x += 15
		else:
			sliding = false
			slideParticles.emitting = false


func handleDashes():
	if (!dashing) && (Input.is_action_just_pressed('dash')) && (availableDashes > 0) && !sliding:
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
			
			if !sliding:
				midairMomentum += (Vector2(250, 100) * dashDirection)
				oldVelocity = oldVelocity + (Vector2(250,200) * dashDirection)
			
			velocity = oldVelocity
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)



func handleWallMechanics():
	if is_on_wall() && !is_on_floor() && !dashing && !sliding:
		var directionX = Input.get_axis('a','d')
		
		if !clinging && (get_wall_normal()[0] * -1) == directionX:
			clinging = true
			clingSpeedWeight = velocity.y
			clingSpeedWeight *= 0.75
			if clingSpeedWeight < 200:
				clingSpeedWeight = 200
			clingEntrySpeed = velocity.y
	else:
		clinging = false
	
	if clinging:
		var directionY = Input.get_axis('s','w')
		
		if directionY == 1:
			pass
		elif directionY == -1:
			pass
		else:
			pass
		if !(clingEntrySpeed > (clingSpeedWeight-5) && clingEntrySpeed < (clingSpeedWeight+5)):
			if velocity.y > clingSpeedWeight:
				clingEntrySpeed -= 4
			else:
				clingEntrySpeed += 4
		velocity.y = clingEntrySpeed
