class_name Dropper
extends Node2D
## The alien spaceship at the top of the jar, holding the next monster in its
## tractor beam. It follows the mouse or finger smoothly, shows a dashed aim
## line down into the jar, and drops the monster when the mouse button or
## finger is released.
##
## SPACESHIP ART
## Until a sprite is set, the ship is drawn in code (see _draw_ship). To use
## your own art, select the Dropper node and drag a PNG into "Ship Texture"
## in the Inspector; "Ship Width" sets how wide it appears.
##
## DROP ORDER
## The very first drop of the game is always Tier 1. After that, every drop is
## a random pick between Tier 1 and TierData.MAX_DROP_TIER (Tier 3).
## Tiers 4 to 7 never drop; they are only made by merging.
## The rule lives in _pick_tier() below.

signal dropped(tier: int, at: Vector2)
signal next_changed(tier: int)

## Height (screen y) where the waiting monster hangs.
@export var hold_y := 250.0
## Seconds between drops.
@export var cooldown := 0.6
## How quickly the monster catches up with the pointer (higher = snappier).
@export var follow_speed := 18.0
@export var aim_line_color := Color(1, 1, 1, 0.35)

@export_group("Spaceship")
## Your spaceship PNG. Leave empty to use the drawn placeholder ship.
@export var ship_texture: Texture2D
## How wide the ship appears, in pixels.
@export var ship_width := 120.0
## How far above the held monster the ship floats.
@export var ship_height_above := 85.0
@export var hull_color := Color(0.62, 0.66, 0.78)
@export var dome_color := Color(0.6, 0.9, 1.0, 0.85)
@export var alien_color := Color(0.55, 0.95, 0.45)
@export var beam_color := Color(0.6, 1.0, 0.8, 0.18)

var enabled := true
var current_tier := 1
var next_tier := 1

var _jar: Jar
var _held: Sprite2D
var _cooldown_left := 0.0
var _target_x := 360.0
var _time := 0.0


func _ready() -> void:
	_held = Sprite2D.new()
	add_child(_held)


## Called once by main.gd when the game starts.
func setup(jar: Jar) -> void:
	_jar = jar
	_target_x = jar.get_inner_rect().get_center().x
	position = Vector2(_target_x, hold_y)
	current_tier = 1  # the first drop of every game is Tier 1
	next_tier = _pick_tier()
	_refresh_held()
	next_changed.emit(next_tier)


## Every drop after the first: random Tier 1, 2 or 3.
func _pick_tier() -> int:
	return randi_range(1, TierData.MAX_DROP_TIER)


func _process(delta: float) -> void:
	if _jar == null:
		return
	_time += delta
	if enabled:
		_target_x = get_global_mouse_position().x
	# Smoothly glide towards the pointer.
	position.x = lerpf(position.x, _clamped_target_x(), 1.0 - exp(-follow_speed * delta))

	if _cooldown_left > 0.0:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0:
			_held.visible = enabled
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or _jar == null:
		return
	# Releasing the mouse button or lifting a finger drops the monster.
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		_target_x = click.position.x
		_drop()


func _drop() -> void:
	if _cooldown_left > 0.0:
		return
	position.x = _clamped_target_x()
	dropped.emit(current_tier, global_position)

	current_tier = next_tier
	next_tier = _pick_tier()
	next_changed.emit(next_tier)
	_refresh_held()
	_held.visible = false
	_cooldown_left = cooldown


func stop() -> void:
	enabled = false
	_held.visible = false
	queue_redraw()


func _refresh_held() -> void:
	_held.texture = TierData.get_texture(current_tier)
	_held.scale = TierData.get_sprite_scale(current_tier)


func _clamped_target_x() -> float:
	var inner := _jar.get_inner_rect()
	var radius := TierData.get_radius(current_tier)
	return clampf(_target_x, inner.position.x + radius, inner.end.x - radius)


func _draw() -> void:
	if _jar == null:
		return
	var ship_y := -ship_height_above + sin(_time * 3.0) * 3.0  # gentle hover
	if _held.visible:
		var radius := TierData.get_radius(current_tier)
		var bottom := _jar.get_floor_y() - position.y
		draw_dashed_line(Vector2(0, radius + 6.0), Vector2(0, bottom), aim_line_color, 3.0, 14.0)
		_draw_beam(ship_y, radius)
	_draw_ship(ship_y)


## Soft tractor beam from the ship down around the held monster.
func _draw_beam(ship_y: float, radius: float) -> void:
	var top_half := ship_width * 0.18
	var bottom_half := radius + 10.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-top_half, ship_y + 10.0), Vector2(top_half, ship_y + 10.0),
		Vector2(bottom_half, radius * 0.6), Vector2(-bottom_half, radius * 0.6),
	]), beam_color)


func _draw_ship(ship_y: float) -> void:
	if ship_texture:
		var tex_size := ship_texture.get_size()
		var draw_size := tex_size * (ship_width / tex_size.x)
		draw_texture_rect(ship_texture, Rect2(Vector2(-draw_size.x / 2.0, ship_y - draw_size.y / 2.0), draw_size), false)
		return

	var half_w := ship_width / 2.0
	# Glass dome with a little alien inside (drawn first so the hull covers its bottom).
	var dome_center := Vector2(0, ship_y - 8.0)
	draw_circle(dome_center, half_w * 0.4, dome_color)
	draw_circle(dome_center + Vector2(0, 4), half_w * 0.22, alien_color)
	for eye_x in [-5.0, 5.0]:
		draw_circle(dome_center + Vector2(eye_x, 1), 3.2, Color.WHITE)
		draw_circle(dome_center + Vector2(eye_x, 1.5), 1.8, Color(0.1, 0.05, 0.15))
	draw_line(dome_center + Vector2(-2, -8), dome_center + Vector2(-6, -16), alien_color, 2.0)
	draw_line(dome_center + Vector2(2, -8), dome_center + Vector2(6, -16), alien_color, 2.0)
	draw_circle(dome_center + Vector2(-6, -16), 2.5, alien_color)
	draw_circle(dome_center + Vector2(6, -16), 2.5, alien_color)

	# Saucer hull: a squashed circle with a darker underside.
	_draw_ellipse(Vector2(0, ship_y + 4.0), half_w * 0.8, half_w * 0.22, hull_color.darkened(0.35))
	_draw_ellipse(Vector2(0, ship_y), half_w, half_w * 0.26, hull_color)

	# Blinking lights around the rim.
	for i in 5:
		var t := (float(i) - 2.0) / 2.0  # -1 .. 1
		var light_pos := Vector2(t * half_w * 0.7, ship_y + 2.0 - (1.0 - absf(t)) * 2.0)
		var on := int(_time * 4.0 + i) % 2 == 0
		draw_circle(light_pos, 4.0, Color(1, 0.9, 0.4) if on else Color(1, 0.5, 0.8))


func _draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, radius_y / radius_x))
	draw_circle(Vector2.ZERO, radius_x, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
