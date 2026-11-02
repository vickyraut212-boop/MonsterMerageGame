class_name Jar
extends Node2D
## The jar the monsters fall into: left wall, right wall, floor, and the
## danger line near the top. If any monster stays above the danger line for
## GAME_OVER_DELAY seconds, the jar emits game_over.
##
## All sizes are in screen pixels (the screen is 720 x 1280).

signal game_over

## Inside of the jar (the space monsters can occupy).
@export var inner_left := 60.0
@export var inner_top := 300.0
@export var inner_width := 600.0
@export var inner_height := 880.0

## How thick the walls look and collide.
@export var wall_thickness := 24.0

## How far below the rim the danger line sits.
@export var danger_line_offset := 40.0

## Seconds a monster may stay above the danger line before game over.
@export var game_over_delay := 2.0

## Surface feel: friction (0 = ice, 1 = grippy) and bounce (0 = none, 1 = full).
@export var wall_friction := 0.6
@export var wall_bounce := 0.05

@export var wall_color := Color(0.85, 0.82, 0.95)
@export var danger_color := Color(1.0, 0.35, 0.4)

var _danger_zone: Area2D
## How long each monster (by instance id) has been above the danger line.
var _time_above_line := {}
var _in_danger := false
var _is_over := false


func _ready() -> void:
	_build_walls()
	_build_danger_zone()
	queue_redraw()


## The inside of the jar as a rectangle.
func get_inner_rect() -> Rect2:
	return Rect2(inner_left, inner_top, inner_width, inner_height)


func get_floor_y() -> float:
	return inner_top + inner_height


func get_danger_y() -> float:
	return inner_top + danger_line_offset


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	var surface := PhysicsMaterial.new()
	surface.friction = wall_friction
	surface.bounce = wall_bounce
	walls.physics_material_override = surface
	add_child(walls)

	var t := wall_thickness
	var right := inner_left + inner_width
	var floor_y := get_floor_y()
	# Side walls reach up to the top of the screen (invisible above the rim)
	# so a bouncing monster can never fly out of the jar.
	_add_wall(walls, Rect2(inner_left - t, 0.0, t, floor_y + t))
	_add_wall(walls, Rect2(right, 0.0, t, floor_y + t))
	_add_wall(walls, Rect2(inner_left - t, floor_y, inner_width + t * 2.0, t))


func _add_wall(parent: Node, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = rect.get_center()
	parent.add_child(collider)


func _build_danger_zone() -> void:
	# Covers the space inside the jar from the danger line up to the top of the screen.
	_danger_zone = Area2D.new()
	_danger_zone.name = "DangerZone"
	_danger_zone.monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(inner_width, get_danger_y())
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(inner_left + inner_width / 2.0, get_danger_y() / 2.0)
	_danger_zone.add_child(collider)
	add_child(_danger_zone)


func _physics_process(delta: float) -> void:
	if _is_over:
		return
	var still_above := {}
	var longest := 0.0
	for body in _danger_zone.get_overlapping_bodies():
		if not _counts_for_danger(body):
			continue
		var id := body.get_instance_id()
		var time_above: float = _time_above_line.get(id, 0.0) + delta
		still_above[id] = time_above
		longest = maxf(longest, time_above)
	_time_above_line = still_above

	var in_danger := not still_above.is_empty()
	if in_danger != _in_danger:
		_in_danger = in_danger
		queue_redraw()

	if longest >= game_over_delay:
		_is_over = true
		game_over.emit()


## Only monsters that have been dropped count (not the one held by the dropper).
func _counts_for_danger(body: Node) -> bool:
	if not body.is_in_group("monsters"):
		return false
	if body is RigidBody2D and (body as RigidBody2D).freeze:
		return false
	return true


func _draw() -> void:
	var t := wall_thickness
	var right := inner_left + inner_width
	var floor_y := get_floor_y()
	var wall_height := inner_height + t
	draw_rect(Rect2(inner_left - t, inner_top, t, wall_height), wall_color)
	draw_rect(Rect2(right, inner_top, t, wall_height), wall_color)
	draw_rect(Rect2(inner_left - t, floor_y, inner_width + t * 2.0, t), wall_color)

	var line_color := danger_color if _in_danger else Color(danger_color, 0.45)
	var y := get_danger_y()
	draw_dashed_line(Vector2(inner_left, y), Vector2(right, y), line_color, 4.0, 16.0)
