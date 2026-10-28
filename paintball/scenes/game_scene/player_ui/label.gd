extends Label

@onready var bar: ColorRect = get_parent()
@onready var label_size: float = get_theme_font_size("font_size") / bar.size.y

func _process(_delta: float) -> void:
	add_theme_font_size_override("font_size", label_size * bar.size.y)
