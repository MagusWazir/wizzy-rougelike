extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"



func _download():
	var wizzyid = $LineEdit.text
	# Create an HTTP request node and connect its completion signal
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var http_error = http_request.request("https://www.forgottenrunes.com/api/art/wizards/"+wizzyid+"/spritesheet.png")
	if http_error != OK:
		print("An error occurred in the HTTP request.")

# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	$Loading.hide()
	get_parent().get_parent().get_node("TileMap").show()
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	print("Start!")
	if image_error != OK:
		print("An error occurred while trying to display the image.")

	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)

	# Assign to the child TextureRect node
	texture = new_texture





func _on_Button_pressed():
	_download()
	$Button.hide()
	$LineEdit.hide()
	$Label.hide()
	$Loading.show()
	pass # Replace with function body.
