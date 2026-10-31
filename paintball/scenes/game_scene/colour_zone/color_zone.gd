extends Node2D

@onready var turret: StaticBody2D = $Turret
@onready var turret_colorwheel: Node2D = $TurretColorWheel
@onready var capture_zone: Area2D = $ColourRange
@onready var zone_captured_audio: AudioStreamPlayer = $ZoneCaptured

var SCORE_REWARD: float = 16.0
var CAPTURE_THRESHOLD: float = 64.0
var score_bias: float = 0.0:
	set(value):
		score_bias = clamp(value, -255.0, 255.0)

var players_in_zone: Array[CharacterBody2D] = []
var candidate_team: int
var is_claimable: bool = false
var is_captured: bool = false
var captured_team: int = -1 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("color_zone")
	turret.last_hit_attacker.connect(score_system)
	capture_zone.body_entered.connect(_on_body_entered)
	capture_zone.area_entered.connect(_on_area_entered)
	capture_zone.body_exited.connect(_on_body_exited)

func score_system(team_id: int) -> void:
	if team_id == 1:
		score_bias += SCORE_REWARD
	elif team_id == 2:
		score_bias -= SCORE_REWARD
	if score_bias > 0:
		turret_colorwheel.score = Vector3(absf(score_bias), 255., 0)
	elif score_bias < 0:
		turret_colorwheel.score = Vector3(0, 255., absf(score_bias))
	else:
		turret_colorwheel.score = Vector3(0, 255., 0)
	if score_bias > CAPTURE_THRESHOLD:
		candidate_team = 1
		is_claimable = true
		turret_colorwheel.claimable_animation(true)
	elif score_bias < -CAPTURE_THRESHOLD:
		candidate_team = 2
		is_claimable = true
		turret_colorwheel.claimable_animation(true)
	else:
		is_claimable = false
		turret_colorwheel.claimable_animation(false)
		overthrown()

func _process(_delta: float) -> void:
	if not is_claimable:
		return
	players_in_zone = players_in_zone.filter(
		func(target):
			return is_instance_valid(target) and not target.is_dead and target.TEAM_ID == candidate_team
	)
	for player in players_in_zone:
		if player.is_stun or player.is_climbing or player.is_aiming:
			continue
		if player.input_up:
			capture_by(player)
			
func capture_by(player: CharacterBody2D) -> void:
	zone_captured_audio.play()
	captured_team = player.TEAM_ID
	turret.TEAM_ID = captured_team
	get_parent().activate_player_base(captured_team)
	turret_colorwheel.captured()
	match captured_team:
		1: turret.update_shadow_color(Globals.p1_color)
		2: turret.update_shadow_color(Globals.p2_color)
	is_captured = true
	
func overthrown() -> void:
	if captured_team == -1:
		return
	get_parent().deactivate_player_base(captured_team)
	captured_team = -1
	turret.TEAM_ID = captured_team
	turret_colorwheel.spawn_animation()
	turret.update_shadow_color(Color.BLACK)
	is_captured = false
	
func _on_body_entered(body: Node2D) -> void:
	_hit_target(body, true)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area, true)

func _on_body_exited(body: Node2D) -> void:
	_hit_target(body, false)

# Hitbox Manager
func _hit_target(target: Node, hit: bool) -> void:
	if target.is_in_group("player"):
		if hit:
			if not players_in_zone.has(target):
				players_in_zone.append(target)
		else:
			players_in_zone.erase(target)
