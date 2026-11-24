extends CharacterBody2D

const UP = Vector2(0, -1)
const speed = 500

var doubleJumps = 1

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !(is_on_floor()):
		velocity += get_gravity() * delta
	else:
		doubleJumps = 1
	
	#region | Handling jumps
	if (Input.is_action_just_pressed('space')):
		if (is_on_floor()):
			velocity.y -= 500
		elif (doubleJumps > 0):
			doubleJumps -= 1
			velocity.y = 0
			velocity.y -= 500
	
	#endregion
	
	var directionX = Input.get_axis('a', 'd')
	velocity.x = directionX * speed
	
	move_and_slide()
