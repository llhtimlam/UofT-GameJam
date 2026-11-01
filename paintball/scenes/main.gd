extends Node2D

const START_SCENE = preload("res://scenes/tutorial/tutorial_ui.tscn")
var tutorial_instance: CanvasLayer

func _ready() -> void:
	load_game()

func load_game():
	tutorial_instance = START_SCENE.instantiate()
	add_child(tutorial_instance)
