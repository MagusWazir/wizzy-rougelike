extends Node2D

var FCT = preload("res://Assets/Scenes/Effects/FCT.tscn")

export var travel = Vector2(0, -30)
export var duration = .7
export var spread = PI/5

func show_value(value, crit=false):
	var fct = FCT.instance()
	add_child(fct)
	fct.show_value(str(value), travel, duration, spread, crit)
