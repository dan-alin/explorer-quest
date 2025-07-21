class_name AttackArc extends Node2D

@export var arc_range: float = 60.0
@export var arc_angle: float = 90.0  # degrees
@export var arc_thickness: float = 3.0
@export var arc_color: Color = Color.YELLOW
@export var animation_duration: float = 0.2

var tween: Tween

func _ready() -> void:
	# Start invisible
	modulate.a = 0.0

func show_arc(direction: Vector2) -> void:
	# Set rotation to face the attack direction
	rotation = direction.angle()
	
	# Animate the arc appearing and disappearing
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Fade in quickly, then fade out
	tween.tween_property(self, "modulate:a", 1.0, animation_duration * 0.3)
	tween.tween_property(self, "modulate:a", 0.0, animation_duration * 0.7)

func _draw() -> void:
	# Draw an arc to show attack range
	var start_angle = -arc_angle * 0.5 * PI / 180.0  # Convert to radians
	var end_angle = arc_angle * 0.5 * PI / 180.0
	var point_count = 32
	
	# Draw the arc outline
	var points: PackedVector2Array = []
	
	# Add center point
	points.append(Vector2.ZERO)
	
	# Add arc points
	for i in range(point_count + 1):
		var angle = start_angle + (end_angle - start_angle) * i / point_count
		var point = Vector2(cos(angle), sin(angle)) * arc_range
		points.append(point)
	
	# Draw filled polygon for the arc
	draw_colored_polygon(points, arc_color * Color(1, 1, 1, 0.3))  # Semi-transparent fill
	
	# Draw arc outline
	for i in range(point_count):
		var angle1 = start_angle + (end_angle - start_angle) * i / point_count
		var angle2 = start_angle + (end_angle - start_angle) * (i + 1) / point_count
		var point1 = Vector2(cos(angle1), sin(angle1)) * arc_range
		var point2 = Vector2(cos(angle2), sin(angle2)) * arc_range
		draw_line(point1, point2, arc_color, arc_thickness)
	
	# Draw the two side lines
	var side1 = Vector2(cos(start_angle), sin(start_angle)) * arc_range
	var side2 = Vector2(cos(end_angle), sin(end_angle)) * arc_range
	draw_line(Vector2.ZERO, side1, arc_color, arc_thickness)
	draw_line(Vector2.ZERO, side2, arc_color, arc_thickness)
