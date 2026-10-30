extends Area2D
class_name Bucket

var score: Vector3 = Vector3.ZERO: # Format: (P1, Turret, P2)
	set(value):
		score = value.clamp(Vector3.ZERO, Vector3(255.0, 255.0, 255.0))
		# Cap and scale from 64 instead of max score 255
		var normalized_score = (score / 64.0).clamp(Vector3.ZERO, Vector3.ONE)
		# Color dilution (default white to player color)
		var final_rgb = Vector3(1.0, 1.0, 1.0)
		
		# Directly subtract from the white channels based on absolute score.
		final_rgb -= (Vector3(1.0, 1.0, 1.0) - Globals.normalized_p1_color) * normalized_score.x
		final_rgb -= (Vector3(1.0, 1.0, 1.0) - Globals.normalized_turret_color) * normalized_score.y
		final_rgb -= (Vector3(1.0, 1.0, 1.0) - Globals.normalized_p2_color) * normalized_score.z
		
		final_rgb = final_rgb.clamp(Vector3.ZERO, Vector3.ONE)
		var calculated_color = Color(final_rgb.x, final_rgb.y, final_rgb.z, 1.0)
		#var final_color = calculated_color.lerp(Color.WHITE, Globals.white_blend_intensity)
		update_color(calculated_color)

var siphoned_team: int

var pickable_players: Array[CharacterBody2D] = []
var carrier: CharacterBody2D = null
var delivered: bool = false

const BUCKET_SCENE = preload("res://scenes/game_scene/paint_bucket/paint_bucket.tscn")
@onready var paint: Sprite2D = $Bucket

func _ready() -> void:
	add_to_group("bucket")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	body_exited.connect(_on_body_exited)
	
func _process(_delta: float) -> void:
	if carrier != null or delivered:
		return
	pickable_players = pickable_players.filter(
		func(target):
			return is_instance_valid(target) and not target.is_dead and target.TEAM_ID != siphoned_team
	)
	for player in pickable_players:
		if player.is_stun or player.is_climbing or player.is_aiming:
			continue
		if player.input_up:
			pickup(player)
	
static func spawn(map: Node2D, siphoned_team: int, spawn_position: Vector2, s_score: Vector3 = Vector3.ZERO) -> Area2D:
	var bucket = BUCKET_SCENE.instantiate()
	map.add_child(bucket)
	bucket.score = s_score
	bucket.siphoned_team = siphoned_team
	bucket.global_position = spawn_position
	return bucket
	
func pickup(player: CharacterBody2D) -> void:
	if carrier != null or delivered:
		return
	if player.held_bucket != null:
		var combined_score = player.held_bucket.score + score
		player.held_bucket.score = combined_score
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
	if base.TEAM_ID != carrier.TEAM_ID:
		return
	delivered = true
	carrier.is_slow = false
	carrier.held_bucket = null
	carrier = null
	base.deposit_score(score)
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
			var combined_score = attacker.held_bucket.score + score
			attacker.held_bucket.score = combined_score
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
	if target.is_in_group("base") and is_instance_valid(target):
		deliver(target)
	if target.is_in_group("bucket") and is_instance_valid(target):
		if is_queued_for_deletion() or target.is_queued_for_deletion():
			return
		if target.siphoned_team == siphoned_team:
			if get_instance_id() < target.get_instance_id():
				if not is_instance_valid(target):
					return
				# Wait for animation player finished
				await get_tree().create_timer(0.5).timeout
				var combined_score = target.score + score
				target.score = combined_score
				score = Vector3.ZERO
				call_deferred("queue_free")

func update_color(color: Color) -> void:
	if paint:
		paint.self_modulate = Color.WHITE
		paint.self_modulate = color
