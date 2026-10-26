extends Node2D

const UI_SCENE = preload("res://scenes/game_scene/ui.tscn")
var ui_instance: CanvasLayer

func _ready() -> void:
	load_game()

func load_game():
	ui_instance = UI_SCENE.instantiate()
	add_child(ui_instance)
