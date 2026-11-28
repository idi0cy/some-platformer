extends CharacterBody2D

#region | Setting up initial variables

@onready var playerSprite = get_node('Sprite2D')

@onready var hitbox = get_node('hitbox')
@onready var hurtbox = get_node('hurtbox')

@onready var coyoteTimer = get_node('coyoteFrames')
@onready var inputBuffer = get_node('inputBuffer')
@onready var slideDashBuffer = get_node('dashToSlideBuffer')

@onready var slideParticles = get_node('slideParticles')
@onready var clingingParticles = get_node('clingingParticles')

const jumpPower_default = 750
const accel_default = 50
const speed_default = 250

const accel = 50
const speed = 250
var jumpPower = 750
const slideStopHopPower = 500
const dashSpeed = 1250 + speed

var momentum = Vector2(0,0)
var leftRightPlayer = 0
var leftRightValue = 0
var dashMomentum = Vector2(0,0)
var groundedMomentum = Vector2(0,0)

var jumping = false
var accelJumping = false
var deaccelJumping = false
var jumpMomentum = 0

var slideStopHopMomentum = 0
var slideStopHopping = false

var playerGravity = Vector2(0,0)

const slideThresh = 500
var slideSpeed = 0
var sliding = false
var slideDashDirection = 0

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

var A = 100
var B = 200

func _process(delta: float) -> void:
	A = A + (B - A) * 0.2
	
	if !(is_on_floor()):
		if !dashing && !clinging && !jumping && !slideStopHopping:
			playerGravity += get_gravity() * delta
	else:
		if !dashing:
			availableDashes = 1
			jumpMomentum = 0
			slideStopHopMomentum = 0
	
	if is_on_floor():
		playerGravity = Vector2(0,0)
	
	if jumpMomentum != 0:
		jumping = true
	else:
		jumping = false
	
	if slideStopHopMomentum != 0:
		slideStopHopping = true
	else:
		slideStopHopping = false
	
	handleSlides()
	handleJumps()
	handleMomentum()
	handleDashes()
	handleWallMechanics()
	
	move_and_slide()



#I'll have to rework this system like every five seconds bruh
func handleMomentum():
	
	if !dashing && !sliding:
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
		velocity.y = dashMomentum[1] - jumpMomentum - slideStopHopMomentum
		velocity += playerGravity
	elif sliding && !dashing:
		velocity.x = slideSpeed



func handleJumps():
	if is_on_floor():
		coyoteTimer.start()
	if Input.is_action_just_pressed('space'):
		inputBuffer.start()
	
	if !coyoteTimer.is_stopped() && !inputBuffer.is_stopped() && !dashing:
		playerGravity = Vector2(0,0)
		jump()
		coyoteTimer.stop()
		inputBuffer.stop()
	
	if jumping:
		if accelJumping:
			if jumpMomentum > 100:
				jumpMomentum = jumpMomentum + (100 - jumpMomentum) * 0.2
		elif deaccelJumping:
			pass
			
		else:
			pass
		if jumpMomentum < 0:
			jumpMomentum = 0
		
		if floor(jumpMomentum) - 2 < 100:
			accelJumping = false
			jumpMomentum = 0
		if is_on_ceiling():
			jumpMomentum = 0
	if slideStopHopping:
		if slideStopHopMomentum > 75:
			slideStopHopMomentum = slideStopHopMomentum + (75 - slideStopHopMomentum) * 0.2
		
		if floor(slideStopHopMomentum) - 2 < 75:
			slideStopHopMomentum = 0
		if is_on_ceiling():
			slideStopHopMomentum = 0
func jump():
	accelJumping = true
	jumpMomentum += jumpPower
	sliding = false
	slideParticles.emitting = false
func shortJump():
	slideStopHopMomentum += slideStopHopPower
	#jumpMomentum -= (jumpPower - 150)
	sliding = false
	slideParticles.emitting = false



func handleSlides():
	if Input.is_action_pressed("s") && !sliding && is_on_floor() && abs(velocity.x) > (speed) && !dashing:
		sliding = true
		slideSpeed = velocity.x * 1.15
		slideParticles.emitting = true
	elif !slideDashBuffer.is_stopped() && !sliding && is_on_floor() && !dashing:
		if slideDashDirection == 0 || slideDashDirection == 1:
			slideSpeed = 450 * 1.15
		else:
			slideSpeed = -(450 * 1.15)
		sliding = true
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
		if is_on_floor():
			shortJump()
	
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
			jumpMomentum = 0
			availableDashes -= 1
			
			coyoteTimer.stop()
			
			velocity = dashDirection * dashSpeed
			dashing = true
			$Sprite2D.modulate = Color(0.0, 1.0, 1.0, 1.0)
			
			playerGravity = Vector2(0,0)
			await get_tree().create_timer(0.15).timeout
			dashing = false
			
			dashMomentum = dashDirection * 200
			
			velocity = Vector2(0,0)
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			if dashDirection != Vector2(0, 1):
				slideDashDirection = floor(dashDirection[0])
				slideDashBuffer.start()
	
	if (dashMomentum[0] < 10 && dashMomentum[0] > -10) && (dashMomentum[1] < 10 && dashMomentum[1] > -10):
		dashMomentum = Vector2(0,0)
	else:
		if dashMomentum[0] > 0:
			dashMomentum[0] -= 4
		else:
			dashMomentum[0] += 4
		if dashMomentum[1] > 0:
			dashMomentum[1] -= 4
		else:
			dashMomentum[1] += 4
	if is_on_floor():
		dashMomentum = Vector2(0,0)



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
