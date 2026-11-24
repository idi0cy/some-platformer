extends CharacterBody2D

const UP = Vector2(0, -1)
const speed = 500

var collisionDown = true
var collisionUp = true
var collisionLeft = true
var collisionRight = true

var momentumX : float
var momentumY : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	momentumX = 0
	momentumY = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !(is_on_floor()):
		velocity += get_gravity() * delta
	else:
		if Input.is_action_just_pressed('space'):
			print('something')
			velocity.y -= 500
	
	if Input.is_action_pressed('a'):
		print('pressing down a')
	if Input.is_action_pressed("d"):
		print('pressing down d')
	
	move_and_slide()
