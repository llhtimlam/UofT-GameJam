extends Node2D
@onready var turret: StaticBody2D = $Turret
var colour : Color = Color(60,50,0)
var capturable : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	turret.can_capture.connect(can_be_captured)

func _on_colour_range_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func can_be_captured(player_team) -> void:
	#TODO: let player choose if they want to steal or capture
	capturable = true
	stolen(player_team)
	
func stolen(player_team) -> void:
	if player_team == 1:
		get_parent().player1Colour += colour
		get_parent().player1Colour.a = 1.0
	else:
		get_parent().player2Colour += colour
		get_parent().player1Colour.a = 1.0
