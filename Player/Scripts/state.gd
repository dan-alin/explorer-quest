class_name State extends Node

## Player reference
static var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

## what hapens when the player enters this state?
func Enter() -> void:
	pass
	
func Exit() -> void:
	pass

func Process(_delta: float) -> State:
	return null
	

func Physics(_delta: float) -> State:
	return null 


func HandleInput(_event: InputEvent) -> State:
	return null 
