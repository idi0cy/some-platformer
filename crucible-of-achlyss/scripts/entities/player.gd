extends CharacterBody2D

#region | Setting up initial variables
const UP = Vector2(0, -1)
const speed = 300
const dashSpeed = 2000

var dashing = false
var availableDashes = 1
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
	
	#region | Handling jumps
	if (Input.is_action_just_pressed('space')) && !dashing:
		if (is_on_floor()):
			velocity.y -= 500
	#endregion
	
	#region | Handling dashes
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
			velocity = oldVelocity
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	#endregion
	
	# This just moves left and right
	if !dashing:
		var directionX = Input.get_axis('a', 'd')
		velocity.x = directionX * speed
	
	#region | Wall jumping and all that
	
	if (is_on_wall() && Input.is_action_just_pressed("space")):
		print(200 * get_wall_normal()[0])
		velocity.x += 200 * get_wall_normal()[0]
		velocity.y += 150
	
	
	if (is_on_wall() && velocity.y > 0):
		if velocity.y > 150:
			velocity.y = 150
	
	#endregion
	
	move_and_slide()
