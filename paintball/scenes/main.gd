extends Node2D

const UI_SCENE = preload("res://scenes/game_scene/ui.tscn")
var ui_instance: CanvasLayer

func _ready() -> void:
	load_game()

func load_game():
	ui_instance = UI_SCENE.instantiate()
	add_child(ui_instance)
	
	var viewport1 = ui_instance.get_node("HBoxContainer/SubViewportContainer1/Viewport1")
	var viewport2 = ui_instance.get_node("HBoxContainer/SubViewportContainer2/Viewport2")
	var camera1 = viewport1.get_node("Map/Player1/Camera2D")
	var camera2 = viewport1.get_node("Map/Player2/Camera2D")
	
	viewport2.world_2d = viewport1.world_2d
	camera1.custom_viewport = viewport1
	camera1.make_current()
	camera2.custom_viewport = viewport2
	camera2.make_current()
