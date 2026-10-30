extends Node2D

# Orientation
var TEAM_ID: int = -1:
	set(value):
		TEAM_ID = value

# Display
@onready var display_triangle: Sprite2D = $ColorWheel

# Animation
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Shader input: 0.0 to 1.0 Normalized Color Vectors (Vector3)
var display_middle_rgb: Vector3 = Vector3.ZERO:
	set(value):
		display_middle_rgb = value
		if is_inside_tree() and display_triangle and display_triangle.material is ShaderMaterial:
			display_triangle.material.set_shader_parameter("custom_color_middle", value)
var display_left_rgb: Vector3 = Vector3.ZERO:
	set(value):
		display_left_rgb = value
		if is_inside_tree() and display_triangle and display_triangle.material is ShaderMaterial:
			display_triangle.material.set_shader_parameter("custom_color_left", value)
var display_right_rgb: Vector3 = Vector3.ZERO:
	set(value):
		display_right_rgb = value
		if is_inside_tree() and display_triangle and display_triangle.material is ShaderMaterial:
			display_triangle.material.set_shader_parameter("custom_color_right", value)

# Score: Self: infinite, P1 P2 : 0
var normalized_score: Vector3 = Vector3(0., 1., 0.)
var score: Vector3 = Vector3(0., 255., 0.): # Format: (P1, Turret, P2)
	set(value):
		score = value.clamp(Vector3.ZERO, Vector3(64.0, 255.0, 64.0))
		# Cap and scale from 96 instead of max score 255
		var normalized_score = (score / 96.0).clamp(Vector3.ZERO, Vector3.ONE)
		# Tug of war color dilution (default white to player color)
		# P1 gain score, subtract from P2, if 0, gain score vice versa
		var diluted_sides_rgb: Vector3 = Vector3(1.0, 1.0, 1.0)
		# P1
		if normalized_score.x > 0:
			diluted_sides_rgb = Vector3(1.0, 1.0, 1.0).lerp(Globals.normalized_p1_color, normalized_score.x)
		# P2
		elif normalized_score.z > 0:
			diluted_sides_rgb = Vector3(1.0, 1.0, 1.0).lerp(Globals.normalized_p2_color, normalized_score.z)

		# Turret Display: Middle: turret, Left, Right: winning player color
		if TEAM_ID == - 1:
			display_middle_rgb = Globals.normalized_turret_color * normalized_score.y
			display_left_rgb = diluted_sides_rgb
			display_right_rgb = diluted_sides_rgb

func _ready() -> void:
	if display_triangle and display_triangle.material:
		display_triangle.material = display_triangle.material.duplicate()
	score = Vector3(0., 255., 0.)
	spawn_animation()
	
func captured() -> void:
	self.visible = false
	claimable_animation(false)
	
func spawn_animation() -> void:
	self.visible = true
	anim_player.play("spawn")
	
func claimable_animation(play: bool) -> void:
	if play:
		anim_player.play("claimable")
	else:
		anim_player.play("RESET")
		anim_player.advance(0)
		anim_player.stop(true)
	
func _process(delta: float) -> void:
	pass
