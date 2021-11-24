extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var speed = 200  # speed in pixels/sec

var velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func get_input():
	velocity = Vector2.ZERO
	if Input.is_action_pressed('right'):
		velocity.x += 1
		$Sprite/AnimationPlayer.play("walk_right")
	if Input.is_action_pressed('left'):
		velocity.x -= 1
		$Sprite/AnimationPlayer.play("walk_left")
	if Input.is_action_pressed('down'):
		velocity.y += 1
		$Sprite/AnimationPlayer.play("walk_down")
	if Input.is_action_pressed('up'):
		velocity.y -= 1
		$Sprite/AnimationPlayer.play("walk_up")
	if velocity == Vector2.ZERO:
		$Sprite/AnimationPlayer.play("idle")
		
	velocity = velocity.normalized() * speed

func _physics_process(delta):
	get_input()
	velocity = move_and_slide(velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
