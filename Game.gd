extends Node2D

#CONSTANTS
enum {PLAYER, ENEMY, ALLY, EFFECT}
const TILE_SIZE = 50
const LEVEL_SIZES = [
	Vector2(50,50)
	]
const LEVEL_ROOM_COUNTS = [5,7,9,12,15]
const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 10

enum Tile {PlaceHolder, Placeholder, Wall, Floor, Door, Ladder, Stone}

# Current Level --------------------

var level_num = 0
var map = []
var rooms = []
var level_size

#VARIABLES
#Gamestate -----
var player_tile
var gamestate = PLAYER
var enemyCounter = 0
var maxEnemy = 2

#NODE REFRENCES
onready var player = $Player
var enemy
var enemy2
var enemies
onready var tile_map = $Terrain



#SIGNALS
signal gamestate_change(gamestate)
signal move_enemy(id)
signal move_player

func _ready():
	randomize()
	build_level()
	
	if $Player:
		player = $Player
		player.connect("action", self, "_on_player_action")
		self.connect("move_player", player, "allow_move")
		player.connect("death",self,"_on_death")
	if $Enemy:
		enemy = $Enemy
		self.connect("move_enemy", enemy, "enemy_movement")
		enemy.connect("enemy_action", self, "_on_enemy_action")
		enemy.connect("death",self,"_on_death")
	if $Enemy2:
		enemy2 = $Enemy2
		self.connect("move_enemy", enemy2, "enemy_movement")
		enemy2.connect("enemy_action", self, "_on_enemy_action")
		enemy2.connect("death",self,"_on_death")
	enemies = [enemy, enemy2]
	pass

func _on_player_action():
	change_gamestate(ENEMY)
	enemyCounter = 0
	_move_enemy()
	#emit_signal("gamestate_change", gamestate)

func _on_enemy_action():
	enemyCounter += 1
	if(enemyCounter < enemies.size()):
		_move_enemy()
	#TODO Change to max number of enemies currently on board
	else:
		change_gamestate(PLAYER)
	pass

func _move_enemy():
	if(enemyCounter < enemies.size()):
		emit_signal("move_enemy", enemies[enemyCounter])
	else:
		change_gamestate(PLAYER)

func change_gamestate(state):
	gamestate = state
	if gamestate == PLAYER:
		print("Player can move")
		emit_signal("move_player")
		
func _on_death(node):
	if node.enemy == true:
		enemies.erase(node)
		maxEnemy -= 1

# ---- Map generation----------
func build_level():
	#Start with blank map
	
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	level_size = LEVEL_SIZES[level_num]
	for x in range(level_size.x):
		map.append([])
		for y in range(level_size.y):
			map[x].append(Tile.Wall)
			tile_map.set_cell(x,y, Tile.Wall)
			
	var free_regions = [Rect2(Vector2(2,2), level_size - Vector2(4,4))]
	var num_rooms = LEVEL_ROOM_COUNTS[level_num]
	for i in range(num_rooms):
		add_room(free_regions)
		if free_regions.empty():
			break
	connect_rooms()
		
	var start_room = rooms.front()
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	player_tile = Vector2(player_x, player_y)
	player.position = (player_tile * TILE_SIZE) + Vector2(25,25)
	
			
func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()]
		
	var size_x = MIN_ROOM_DIMENSION 
	if region.size.x > MIN_ROOM_DIMENSION:
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION)
	
	var size_y = MIN_ROOM_DIMENSION
	if region.size.y > MIN_ROOM_DIMENSION:
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION)
		
	size_x = min(size_x, MAX_ROOM_DIMENSION)
	size_y = min(size_y, MAX_ROOM_DIMENSION)
		
	var start_x = region.position.x
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x - size_x)
		
	var start_y = region.position.y
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y - size_y)
	
	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	for x in range(start_x, start_x + size_x):
		set_tile(x, start_y, Tile.Wall)
		set_tile(x, start_y + size_y - 1, Tile.Wall)
		
	for y in range(start_y + 1, start_y + size_y - 1):
		set_tile(start_x, y, Tile.Wall)
		set_tile(start_x + size_x - 1, y, Tile.Wall)
		
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, Tile.Floor)
			
	cut_regions(free_regions, room)

func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_queue = []
	
	for region in free_regions:
		if region.intersects(region_to_remove):
			removal_queue.append(region)
			
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
		
			if leftover_left >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
			if leftover_right >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
			if leftover_above >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
			if leftover_below >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))
				
	for region in removal_queue:
		free_regions.erase(region)
		
	for region in addition_queue:
		free_regions.append(region)
	
func set_tile(x, y, type):
	map[x][y] = type
	tile_map.set_cell(x, y, type)

	if type == Tile.Floor:
		clear_path(Vector2(x, y))
		
func clear_path(tile):
	pass
	
func connect_rooms():
	# Build an AStar graph of the area where we can add corridors
	
	var stone_graph = AStar.new()
	var point_id = 0
	for x in range(level_size.x):
		for y in range(level_size.y):
			if map[x][y] == Tile.Wall:
				stone_graph.add_point(point_id, Vector3(x, y, 0))
				
				# Connect to left if also stone
				if x > 0 && map[x - 1][y] == Tile.Wall:
					var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0))
					stone_graph.connect_points(point_id, left_point)
					
				# Connect to above if also stone
				if y > 0 && map[x][y - 1] == Tile.Wall:
					var above_point = stone_graph.get_closest_point(Vector3(x, y - 1, 0))
					stone_graph.connect_points(point_id, above_point)
					
				point_id += 1

	# Build an AStar graph of room connections
	
	var room_graph = AStar.new()
	point_id = 0
	for room in rooms:
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector3(room_center.x, room_center.y , 0))
		point_id += 1
	
	# Add random connections until everything is connected
	
	while !is_everything_connected(room_graph):
		add_random_connection(stone_graph, room_graph)

func is_everything_connected(graph):
	var points = graph.get_points()
	var start = points.pop_back()
	for point in points:
		var path = graph.get_point_path(start, point)
		if !path:
			return false
			
	return true
	
func add_random_connection(stone_graph, room_graph):
	# Pick rooms to connect

	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)
	
	# Pick door locations
	
	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])
	
	# Find a path to connect the doors to each other
	
	var closest_start_point = stone_graph.get_closest_point(start_position)
	var closest_end_point = stone_graph.get_closest_point(end_position)
	
	var path = stone_graph.get_point_path(closest_start_point, closest_end_point)
	#assert(path)
	
	# Add path to the map
	
	path = Array(path)
	
	set_tile(start_position.x, start_position.y, Tile.Door)
	set_tile(end_position.x, end_position.y, Tile.Door)
	
	for position in path:
		set_tile(position.x, position.y, Tile.Floor)
	
	room_graph.connect_points(start_room_id, end_room_id)

func get_least_connected_point(graph):
	var point_ids = graph.get_points()
	
	var least
	var tied_for_least = []
	
	for point in point_ids:
		var count = graph.get_point_connections(point).size()
		if !least || count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)
			
	return tied_for_least[randi() % tied_for_least.size()]
	
func get_nearest_unconnected_point(graph, target_point):
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_points()
	
	var nearest
	var tied_for_nearest = []
	
	for point in point_ids:
		if point == target_point:
			continue
		
		var path = graph.get_point_path(point, target_point)
		if path:
			continue
			
		var dist = (graph.get_point_position(point) - target_position).length()
		if !nearest || dist < nearest:
			nearest = dist
			tied_for_nearest = [point]
		elif dist == nearest:
			tied_for_nearest.append(point)
			
	return tied_for_nearest[randi() % tied_for_nearest.size()]
func pick_random_door_location(room):
	var options = []
	
	# Top and bottom walls
	
	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector3(x, room.position.y, 0))
		options.append(Vector3(x, room.end.y - 1, 0))
			
	# Left and right walls
	
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector3(room.position.x, y, 0))
		options.append(Vector3(room.end.x - 1, y, 0))
			
	return options[randi() % options.size()]
