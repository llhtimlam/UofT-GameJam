extends Area2D
class_name Bucket

var score: Vector3 = Vector3.ZERO: # Format: (P1, Turret, P2)
	set(value):
		var normalized_score = value / 255.0

var pickable_players: Array[CharacterBody2D] = []
var carrier: CharacterBody2D = null
var delivered: bool = false

const BUCKET_SCENE = preload("res://scenes/game_scene/paint_bucket/paint_bucket.tscn")
@onready var paint: Sprite2D = $Paint

func _ready() -> void:
	add_to_group("bucket")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	paint.modulate = Color8(0, 16, 0)
	
func _process(_delta: float) -> void:
	if carrier != null or delivered:
		return
	for player in pickable_players:
		if player.is_stun or player.is_climbing or player.is_aiming:
			continue
		if player.input_up:
			pickup(player)
	
static func spawn(map: Node2D, spawn_position: Vector2, s_score: Vector3 = Vector3.ZERO) -> Area2D:
	var bucket = BUCKET_SCENE.instantiate()
	bucket.score = s_score
	map.add_child.call_deferred(bucket)
	bucket.global_position = spawn_position
	return bucket
	
func pickup(player: CharacterBody2D) -> void:
	if carrier != null or delivered:
		return
	if player.held_bucket != null:
		player.held_bucket.score += score
		call_deferred("queue_free")
		return
	carrier = player
	player.held_bucket = self
	reparent(player.bucket_slot, true)
	position = Vector2.ZERO
	player.is_slow = true
	
func deliver(base: Node2D) -> void:
	if carrier == null:
		return
	delivered = true
	carrier.is_slow = false
	carrier.held_bucket = null
	carrier = null
	base.update_score(score)
	base._get_zoom_animation()
	call_deferred("queue_free")
	
func transfer(attacker_id: int, attacker_team: int) -> void:
	if carrier == null or not is_instance_valid(carrier):
		return
	if attacker_id == -1 or attacker_team == -1:
		return
	var victim: CharacterBody2D = carrier
	for node in get_tree().get_nodes_in_group("player"):
		if node.PLAYER_ID != attacker_id and node.TEAM_ID != attacker_team:
			continue
		var attacker: CharacterBody2D = node
		if attacker == victim or attacker.is_dead:
			return
		if attacker.held_bucket == null:
			victim.held_bucket = null
			victim.is_slow = false
			carrier = attacker
			attacker.held_bucket = self
			reparent(attacker.bucket_slot, false)
			position = Vector2.ZERO
			attacker.is_slow = true
		else:
			attacker.held_bucket.score += score
			victim.held_bucket = null
			victim.is_slow = false
			carrier = null
			score = Vector3.ZERO
			call_deferred("queue_free")
		return
	
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
			if not pickable_players.has(target):
				pickable_players.append(target)
		else:
			pickable_players.erase(target)
	if target.is_in_group("base"):
		deliver(target)
