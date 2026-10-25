extends Node2D

@export var PLAYER1: Node2D
@export var PLAYER2: Node2D
@onready var P1Spawn: Marker2D = $Player1SpawnPoint
@onready var P2Spawn: Marker2D = $Player2SpawnPoint

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PLAYER1.player_eliminated.connect(player_killed)
	PLAYER2.player_eliminated.connect(player_killed)

func player_killed(player):
	#TODO: mobile spawn point once capture points exist
	var spawnpoint
	if player.TEAM_ID == 1:
		spawnpoint = P1Spawn.position
	else:
		spawnpoint = P2Spawn.position
	player.position = spawnpoint
	player.reset_state()
