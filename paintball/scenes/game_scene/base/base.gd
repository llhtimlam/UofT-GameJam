extends Area2D

var TEAM_ID: int = 1
var defender: CharacterBody2D

@onready var colorwheel: Node2D = $ColorWheel
@onready var colorwheel_clone: Node2D = $ColorWheelClone
@onready var hurtbox_clone: CollisionShape2D = $CollisionShape2DClone
@onready var return_colour_audio: AudioStreamPlayer = $ReturnColour
@onready var zone_captured_audio: AudioStreamPlayer = $ZoneCaptured

var score: Vector3 = Vector3.ZERO: # Format: (P1, Turret, P2)
	set(value):
		score = value.clamp(Vector3.ZERO, Vector3(255.0, 255.0, 255.0))
		if colorwheel:
			colorwheel.score = score
		if colorwheel_clone:
			colorwheel_clone.score = score

const MAX_HP: float = 40
var hp: float = MAX_HP

var is_harvesting: bool = false
var SIPHON_AMOUNT: float = 0.4

var REGEN_AMOUNT: float = 0.2
var REGEN_CD: float = 0.2
var regen_timer : float = 0.0

var iframe: float = 0.0
var IFRAME_CD: float = 0.8

var INVADE_PERCENTAGE: = 0.3
var LOSS_PERCENTAGE: = 0.05
var OVERFLOWN_PERCENTAGE: = 0.7

func _ready() -> void:
	add_to_group("base")
	if colorwheel:
		colorwheel.TEAM_ID = TEAM_ID
	if colorwheel_clone:
		colorwheel_clone.TEAM_ID = TEAM_ID
	colorwheel_clone.visible = false
	hurtbox_clone.disabled = true
	
func _physics_process(delta: float) -> void:
	# Timer
	regen_timer = max(regen_timer - delta, 0.0)
	iframe = max(iframe - delta, 0.0)
	if regen_timer <= 0.0:
		_get_regen()
		regen_timer = REGEN_CD
	
func update_score(add_score: Vector3 = Vector3.ZERO) -> void:
	var combined_score = score + add_score
	score = combined_score
	
func take_damage(damage, attacker_id, _attacker_team) -> void:
	if attacker_id == TEAM_ID:
		return
	if iframe > 0:
		return
	hp -= damage
	iframe = IFRAME_CD
	if hp <= 0:
		hp = MAX_HP
		Bucket.spawn(
				get_parent(),
				TEAM_ID,
				_get_spawnpoint(),
				score * INVADE_PERCENTAGE
				)
		if colorwheel:
			colorwheel.hurt_animation()
		if colorwheel_clone:
			colorwheel_clone.hurt_animation()
		var temp_score = score - (score * INVADE_PERCENTAGE)
		score = temp_score
	
func _get_spawnpoint() -> Vector2:
	match TEAM_ID:
		1: return get_parent().bucket_spawn_p1.global_position
		_: return get_parent().bucket_spawn_p2.global_position

func _get_regen() -> void:
	var temp_score = score
	match TEAM_ID:
		1: temp_score.x += REGEN_AMOUNT
		2: temp_score.z += REGEN_AMOUNT
	if is_harvesting:
		temp_score.y += SIPHON_AMOUNT
	score = temp_score 
	
func deposit_score(add_score: Vector3 = Vector3.ZERO) -> void:
	return_colour_audio.play()
	update_score(add_score)
	if colorwheel:
		colorwheel.zoom_animation()
	if colorwheel_clone:
		colorwheel_clone.zoom_animation()
	
func lost_score_to(attacker_base: Node = null) -> void:
	var amount_lost: Vector3 = self.score * LOSS_PERCENTAGE
	var temp_score = score - amount_lost
	self.score -= amount_lost
	score = temp_score
	if colorwheel:
		colorwheel.flip_animation()
	if colorwheel_clone:
		colorwheel_clone.flip_animation()
	if attacker_base != null:
		attacker_base.update_score(amount_lost)
	
func set_outpost(is_deployed: bool) -> void:
	if is_deployed:
		colorwheel_clone.visible = true
		hurtbox_clone.set_deferred("disabled", false)
		is_harvesting = true
	else:
		colorwheel_clone.visible = false
		hurtbox_clone.set_deferred("disabled", true)
		is_harvesting = false

func overthrown(attacker_base: Node = null) -> void:
	zone_captured_audio.play()
	set_outpost(false)
	var amount_lost: Vector3 = self.score * OVERFLOWN_PERCENTAGE
	var temp_score = score - amount_lost
	self.score -= amount_lost
	if attacker_base != null:
		attacker_base.update_score(amount_lost)
