extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var debug = false
export var enemy = false
export var wizzyID = 0
export var enemyID = 0

var moving = false
var attacking = false

var grid_pos

var targetPos = Vector2(0,0)
var t = 0.0
export var player = true

var can_move = true

enum {UP, DOWN, LEFT, RIGHT}

#STATS
export var attack = 1
export var max_hp = 50

#STATE VARIABLES
var hp = max_hp

#SIGNALS
signal action
signal enemy_action
signal death(node)

# Called when the node enters the scene tree for the first time.
func _ready():
	hp = max_hp
	if player:
		if($Camera2D/HP):
			$Camera2D/HP.text = str(max_hp)+"/"+str(max_hp)
	
	grid_pos = Vector2(int(position.x/50), int(position.y/50))
	#Don't let rays collide with self
	for ray in $Rays.get_children():
		ray.add_exception(self)
	
	#TEMP
	_download()
	pass # Replace with function body.

func _input(event):
	if !can_move:
		return
	#Only players should have input
	if !player or enemy:
		return
	#No new actions if currently performing one
	if moving:
		return
	if event.is_action_pressed("left"):
		handle_movement(LEFT)
		can_move = false
	if event.is_action_pressed("right"):
		handle_movement(RIGHT)
		can_move = false
	if event.is_action_pressed("up"):
		handle_movement(UP)
		can_move = false
	if event.is_action_pressed("down"):
		handle_movement(DOWN)
		can_move = false
		


func _process(delta):
	if targetPos && moving:
		position = lerp(position, targetPos, .15)
		if position.x >= targetPos.x-1 && position.x <= targetPos.x+1 && position.y >= targetPos.y - 1 && position.y <= targetPos.y + 1:
			position = targetPos
			moving = false
			$Sprite/AnimationPlayer.seek(0, true)
			$Sprite/AnimationPlayer.stop()
			if player:
				emit_signal("action")
			if enemy:
				emit_signal("enemy_action")
			grid_pos = Vector2(int(position.x/50), int(position.y/50))
	pass

#Handle movement for players AND enimies 
func handle_movement(direction):
	match direction:
		UP:
			$Sprite/AnimationPlayer.play("walk_up")
			$Sprite/AnimationPlayer.seek(0, true)
			$Sprite/AnimationPlayer.stop()
			if(!$Rays/RayUp.get_collider()):
				$Sprite/AnimationPlayer.play("walk_up")
				targetPos = position
				targetPos.y -= 50
				moving = true
			elif $Rays/RayUp.get_collider().name != "Terrain":
				$Sprite/AnimationPlayer.play("attack_up")
				var dmgval = int(rand_range(0,10))
				$Rays/RayUp.get_collider().get_node("FCTManager").show_value(int(dmgval))
				$Rays/RayUp.get_collider().take_damage(dmgval)
		DOWN:
			$Sprite/AnimationPlayer.play("walk_down")
			$Sprite/AnimationPlayer.seek(0, true)
			$Sprite/AnimationPlayer.stop()
			if(!$Rays/RayDown.get_collider()):
				$Sprite/AnimationPlayer.play("walk_down")
				targetPos = position
				targetPos.y += 50
				moving = true
			elif $Rays/RayDown.get_collider().name != "Terrain":
				$Sprite/AnimationPlayer.play("attack_down")
				var dmgval = int(rand_range(0,10))
				$Rays/RayDown.get_collider().get_node("FCTManager").show_value(int(dmgval))
				$Rays/RayDown.get_collider().take_damage(dmgval)
		LEFT:
			$Sprite/AnimationPlayer.play("walk_left")
			$Sprite/AnimationPlayer.seek(0, true)
			$Sprite/AnimationPlayer.stop()
			if(!$Rays/RayLeft.get_collider()):
				$Sprite/AnimationPlayer.play("walk_left")
				targetPos = position
				targetPos.x -= 50
				moving = true
			elif $Rays/RayLeft.get_collider().name != "Terrain":
				$Sprite/AnimationPlayer.play("attack_left")
				var dmgval = int(rand_range(0,10))
				$Rays/RayLeft.get_collider().get_node("FCTManager").show_value(int(dmgval))
				$Rays/RayLeft.get_collider().take_damage(dmgval)

		RIGHT:
			$Sprite/AnimationPlayer.play("walk_right")
			$Sprite/AnimationPlayer.seek(0, true)
			$Sprite/AnimationPlayer.stop()
			if(!$Rays/RayRight.get_collider()):
				$Sprite/AnimationPlayer.play("walk_right")
				targetPos = position
				targetPos.x = int(targetPos.x+50)
				moving = true
			elif $Rays/RayRight.get_collider().name != "Terrain":
				$Sprite/AnimationPlayer.play("attack_right")
				var dmgval = int(rand_range(0,10))
				$Rays/RayRight.get_collider().get_node("FCTManager").show_value(int(dmgval))
				$Rays/RayRight.get_collider().take_damage(dmgval)

	pass

func handle_collision(collisionObject):
	pass

#Animation finished
func animation_finished():
	if player:
		emit_signal("action")
	if enemy:
		emit_signal("enemy_action")
	pass

#Move to seprate file?
func enemy_movement(enemy_node):
	if enemy_node != self:
		return
	#Check if enemy should attack first
	for ray in $Rays.get_children():
		if(ray.get_collider() != null && ray.get_collider().name == "Player"):
			if(ray == $Rays/RayDown):
				handle_movement(DOWN)
			if(ray == $Rays/RayUp):
				handle_movement(UP)
			if(ray == $Rays/RayLeft):
				handle_movement(LEFT)
			if(ray == $Rays/RayRight):
				handle_movement(RIGHT)
			return
	#Go to player but avoid other enemies
	var player_pos = Vector2(0,0)
	if(get_parent().find_node("Player")):
		player_pos = get_parent().find_node("Player").grid_pos
	else:
		player_pos = Vector2(0,0)
	if player_pos.x < grid_pos.x && ($Rays/RayLeft.get_collider() == null):
		handle_movement(LEFT)
	elif player_pos.x > grid_pos.x && ($Rays/RayRight.get_collider() == null):
		handle_movement(RIGHT)
	elif player_pos.y > grid_pos.y && $Rays/RayDown.get_collider() == null:
		handle_movement(DOWN)
	elif player_pos.y < grid_pos.y && ($Rays/RayUp.get_collider() == null):
		handle_movement(UP)
	else:
		emit_signal("enemy_action")
	pass

func allow_move():
	can_move = true

#Combat functions
func take_damage(damage):
	hp = hp - damage
	print(hp)
	if player:
		$Camera2D/HP.text = str(hp)+"/"+str(max_hp)
	if hp <= 0:
		if(enemy):
			emit_signal("death", self)
			emit_signal("enemy_action")
			print("Got here")
		queue_free()
	


#TEMP -------------------------------- Functions for downloading wizzy textures ------------
#Move to a different util file!
func _download():

	if debug:
		return
	# Create an HTTP request node and connect its completion signal
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var http_error = http_request.request("https://www.forgottenrunes.com/api/art/wizards/"+str(wizzyID)+"/spritesheet.png")
	if http_error != OK:
		print("An error occurred in the HTTP request.")

# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)

	if image_error != OK:
		print("An error occurred while trying to display the image.")

	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image, 0)

	# Assign to the child TextureRect node
	$Sprite.texture = new_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
