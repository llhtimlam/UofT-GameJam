extends Node2D

# Orientation
var TEAM_ID: int = 1:
	set(value):
		TEAM_ID = value
		_update_progress_bar_color()

# Display
@onready var display_triangle: Sprite2D = $ColorWheel
@onready var display_middle: TextureProgressBar = $MiddleScore
@onready var display_left: TextureProgressBar = $LeftScore
@onready var display_right: TextureProgressBar = $RightScore

# Animation
var spin_tween: Tween
var zoom_tween: Tween

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

# Progress bar input: 0.0 to 100.0 Progress Bar Percentages (float)
var display_middle_pct: float = 0.0:
	set(value):
		display_middle_pct = value
		if display_middle: display_middle.value = value
var display_left_pct: float = 0.0:
	set(value):
		display_left_pct = value
		if display_left: display_left.value = value
var display_right_pct: float = 0.0:
	set(value):
		display_right_pct = value
		if display_right: display_right.value = value

# Conversion Helper Vector3 (255,255,255) to display triangle and progress bar
var normalized_score: Vector3 = Vector3.ZERO
var score: Vector3 = Vector3.ZERO: # Format: (P1, Turret, P2)
	set(value):
		score = value.clamp(Vector3.ZERO, Vector3(255.0, 255.0, 255.0))
		normalized_score = score / 255.0
		# P1 Display: Middle: P1, Left: P2, Right: turret
		if TEAM_ID == 1:
			display_middle_pct = normalized_score.x * 100
			display_left_pct = normalized_score.z * 100
			display_right_pct = normalized_score.y * 100
			display_middle_rgb = Globals.normalized_p1_color * normalized_score.x
			display_left_rgb = Globals.normalized_p2_color * normalized_score.z
			display_right_rgb = Globals.normalized_turret_color * normalized_score.y
		# P2 Display: Middle: P2, Left: turret, Right: P1
		elif TEAM_ID == 2:
			display_middle_pct = normalized_score.z * 100
			display_left_pct = normalized_score.y * 100
			display_right_pct = normalized_score.x * 100
			display_middle_rgb = Globals.normalized_p2_color * normalized_score.z
			display_left_rgb = Globals.normalized_turret_color * normalized_score.y
			display_right_rgb = Globals.normalized_p1_color * normalized_score.x

func _ready() -> void:
	if display_triangle and display_triangle.material:
		display_triangle.material = display_triangle.material.duplicate()
	_update_progress_bar_color()
	
func _update_progress_bar_color() -> void:
	if not is_inside_tree() or not display_middle:
		return
	# P1 Display: Middle: P1, Left: P2, Right: turret
	if TEAM_ID == 1:
		set_color(
			Globals.p1_color,
			Globals.p2_color,
			Globals.turret_color
			)
	# P2 Display: Middle: P2, Left: turret, Right: P1
	elif TEAM_ID == 2:
		set_color(
			Globals.p2_color,
			Globals.turret_color,
			Globals.p1_color
			)
	
func set_color(middle_color: Color = Color(255,0,0), left_color: Color = Color(0,0,255), right_color: Color = Color(0,255,0)) -> void:
	if display_middle:
		display_middle.self_modulate = Color.WHITE
		display_middle.self_modulate = middle_color 
	if display_left:
		display_left.self_modulate = Color.WHITE
		display_left.self_modulate = left_color
	if display_right:
		display_right.self_modulate = Color.WHITE
		display_right.self_modulate = right_color
	
func hurt_animation() -> void:
	if spin_tween and spin_tween.is_valid():
		spin_tween.kill()
	spin_tween = create_tween()
	spin_tween.set_trans(Tween.TRANS_QUAD)
	spin_tween.set_ease(Tween.EASE_IN_OUT)
	var target_rotation: float = self.rotation + (6 * PI)
	spin_tween.tween_property(self, "rotation", target_rotation, 0.8)
	
func zoom_animation() -> void:
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()
	self.scale = Vector2.ONE
	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	zoom_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	
func flip_animation() -> void:
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()
	self.scale = Vector2.ONE
	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "scale", Vector2(-1.0, -1.0), 0.15)
	zoom_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	
func _process(delta: float) -> void:
	pass
