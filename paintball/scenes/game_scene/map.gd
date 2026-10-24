extends Node2D

@export var PLAYER1: Node2D
@export var PLAYER2: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PLAYER1.player_eliminated.connect(player_killed)
	PLAYER2.player_eliminated.connect(player_killed)

func player_killed(player):
	#TODO: mobile spawn point once capture points exist
	var spawnpoint
	if player.TEAM_ID == 1:
		spawnpoint = $HomeTerritory1.position + Vector2(-250, -100.0)
	else:
		spawnpoint = $HomeTerritory2.position + Vector2(250, -100.0)
	player.position = spawnpoint
	player.reset_state()
