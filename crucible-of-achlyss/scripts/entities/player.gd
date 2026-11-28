extends CharacterBody2D

#region | Setting up initial variables

@onready var playerSprite = get_node('Sprite2D')

@onready var hitbox = get_node('hitbox')
@onready var hurtbox = get_node('hurtbox')

@onready var coyoteTimer = get_node('coyoteFrames')
@onready var inputBuffer = get_node('inputBuffer')

@onready var slideParticles = get_node('slideParticles')
@onready var clingingParticles = get_node('clingingParticles')

const accel = 60
const speed = 300
const jumpPower = 350
const dashSpeed = 1750 + speed

var momentum = Vector2(0,0)
var leftRightPlayer = 0
var leftRightValue = 0
var dashMomentum = Vector2(0,0)
var groundedMomentum = Vector2(0,0)

var jumpMomentum = 0

var playerGravity = Vector2(0,0)

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
	#setting up everything
	playerSprite.show()
	
	slideParticles.show()
	clingingParticles.show()
	
	slideParticles.emitting = false
	clingingParticles.emitting = false

func _process(delta: float) -> void:
	if !(is_on_floor()):
		if !dashing && !clinging:
			playerGravity += get_gravity() * delta
	else:
		if !dashing:
			availableDashes = 1
	
	if is_on_floor():
		playerGravity = Vector2(0,0)
	
	handleSlides()
	handleJumps()
	handleLeftToRight()
	handleDashes()
	handleWallMechanics()
	
	move_and_slide()



#I'll have to rework this system like every five seconds bruh
func handleLeftToRight():
	#if !dashing:
		#var directionX = Input.get_axis('a', 'd')
		#leftRightWeight = directionX * speed
	#
	#if !is_on_floor():
		#if !(midairMomentum[0] < 10 && midairMomentum[0] > -10):
			#if midairMomentum[0] > 0:
				#midairMomentum[0] -= 10
			#else:
				#midairMomentum[0] += 10
	#else:
		#midairMomentum = Vector2(0,0)
	#
	#if !dashing && !sliding && is_on_floor():
		#velocity.x = leftRightWeight
	#elif !dashing && !sliding:
		#
		#if abs(midairMomentum[0]) < abs(leftRightWeight):
			#velocity.x =leftRightWeight
		#else:
			#velocity.x = midairMomentum[0]
	
	#we must program acceleration and decelaration
	
	if !dashing:
		var directionX = Input.get_axis('a','d')
		if abs(directionX) == directionX && directionX != 0:
			if leftRightPlayer < speed:
				leftRightPlayer += accel
			else:
				leftRightPlayer = speed * directionX
		elif directionX != 0:
			if leftRightPlayer > (speed * -1):
				leftRightPlayer -= accel
			else:
				leftRightPlayer = speed * directionX
		else:
			if leftRightPlayer > 0:
				leftRightPlayer -= accel
			elif leftRightPlayer < 0:
				leftRightPlayer += accel
	
		velocity.x = leftRightPlayer + dashMomentum[0]
		velocity.y = dashMomentum[1] + jumpMomentum
		velocity += playerGravity



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
	jumpMomentum -= jumpPower
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
	
	#print(directionX)
	
	if sliding && directionX != 0:
		if (directionX == -1 && abs(velocity.x) == velocity.x):
			if !(slideSpeed > -15 && slideSpeed < 15):
				if slideSpeed > 0:
					slideSpeed -= 15
				else:
					slideSpeed += 15
			else:
				sliding = false
				slideParticles.emitting = false
		elif (directionX == 1 && abs(velocity.x) != velocity.x):
			if !(slideSpeed > -15 && slideSpeed < 15):
				if slideSpeed > 0:
					slideSpeed -= 15
				else:
					slideSpeed += 15
			else:
				sliding = false
				slideParticles.emitting = false
		
		#velocity.x = slideSpeed
	elif sliding && !(Input.is_action_pressed('a') || Input.is_action_pressed('d')):
		if !(slideSpeed > -15 && slideSpeed < 15):
			if slideSpeed > 0:
				slideSpeed -= 15
			else:
				slideSpeed += 15
		else:
			sliding = false
			slideParticles.emitting = false
	if sliding:
		velocity.x = slideSpeed



func handleDashes():
	if (!dashing) && (Input.is_action_just_pressed('dash')) && (availableDashes > 0) && !sliding:
		var dashDirection = Input.get_vector("a", "d", "w", "s")
		
		if dashDirection != Vector2(0,0):
			
			availableDashes -= 1
			
			coyoteTimer.stop()
			
			velocity = dashDirection * dashSpeed
			dashing = true
			$Sprite2D.modulate = Color(0.0, 1.0, 1.0, 1.0)
			
			await get_tree().create_timer(0.1).timeout
			
			dashing = false
			
			if !sliding:
				#midairMomentum += (Vector2(500, 200) * dashDirection)
				pass
			
			playerGravity = Vector2(0,0)
			
			velocity = Vector2(0,0)
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)



func handleWallMechanics():
	if is_on_wall() && !is_on_floor() && !dashing && !sliding:
		var directionX = Input.get_axis('a','d')
		
		if !clinging && (get_wall_normal()[0] * -1) == directionX:
			if directionX == 1:
				clingingParticles.position = Vector2(11,-8)
				clingingParticles.initial_velocity_min = -25
				clingingParticles.initial_velocity_max = -50
			elif directionX == -1:
				clingingParticles.position = Vector2(-11, -8)
				clingingParticles.initial_velocity_min = 25
				clingingParticles.initial_velocity_max = 50
			
			clinging = true
			clingSpeedWeight = velocity.y
			clingSpeedWeight *= 0.75
			if clingSpeedWeight < 200:
				clingSpeedWeight = 200
			clingEntrySpeed = velocity.y
		elif clinging && directionX == 0:
			clinging = false
	else:
		clinging = false
	
	if clinging == true && abs(velocity.y) == velocity.y && velocity.y > 100:
		clingingParticles.emitting = true
	else:
		clingingParticles.emitting = false
	
	if clinging:
		var directionY = Input.get_axis('s','w')
		
		if directionY == 1:
			clingEntrySpeed *= 0.96
		elif directionY == -1:
			if clingEntrySpeed < (clingSpeedWeight * 1.5):
				clingEntrySpeed *= 1.02
		else:
			if !(clingEntrySpeed > (clingSpeedWeight-5) && clingEntrySpeed < (clingSpeedWeight+5)):
				if velocity.y > clingSpeedWeight:
					clingEntrySpeed -= 4
				else:
					clingEntrySpeed += 4
		velocity.y = clingEntrySpeed
		
	if clinging:
		if Input.is_action_just_pressed("space"):
			var directionX = Input.get_axis('a','d')
			clinging = false
			wallJump(directionX * -1)
func wallJump(orientation):
	velocity.y = -400
