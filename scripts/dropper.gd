class_name Dropper
extends Node2D
## The monster waiting at the top of the jar. It follows the mouse or finger
## smoothly, shows a dashed aim line down into the jar, and drops the monster
## when the mouse button or finger is released.
##
## DROP ORDER
## The very first drop is always Tier 1. After that, a tier can only drop once
## the player has already made it by merging, and never above
## TierData.MAX_DROP_TIER (Tier 3). So the game starts with only Tier 1s, Tier 2
## joins the drops after the first Tier 2 merge, then Tier 3.
## The rule lives in _pick_tier() below.

signal dropped(tier: int, at: Vector2)
signal next_changed(tier: int)

## Height (screen y) where the waiting monster hangs.
@export var hold_y := 215.0
## Seconds between drops.
@export var cooldown := 0.6
## How quickly the monster catches up with the pointer (higher = snappier).
@export var follow_speed := 18.0
@export var aim_line_color := Color(1, 1, 1, 0.35)

var enabled := true
var current_tier := 1
var next_tier := 1

var _jar: Jar
var _held: Sprite2D
var _highest_unlocked := 1
var _cooldown_left := 0.0
var _target_x := 360.0


func _ready() -> void:
	_held = Sprite2D.new()
	add_child(_held)


## Called once by main.gd when the game starts.
func setup(jar: Jar) -> void:
	_jar = jar
	_target_x = jar.get_inner_rect().get_center().x
	position = Vector2(_target_x, hold_y)
	current_tier = 1
	next_tier = _pick_tier()
	_refresh_held()
	next_changed.emit(next_tier)


## Called when the player makes a new tier by merging.
func unlock_tier(tier: int) -> void:
	_highest_unlocked = clampi(maxi(_highest_unlocked, tier), 1, TierData.MAX_DROP_TIER)


func _pick_tier() -> int:
	return randi_range(1, _highest_unlocked)


func _process(delta: float) -> void:
	if _jar == null:
		return
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
	if _jar == null or not _held.visible:
		return
	var radius := TierData.get_radius(current_tier)
	var bottom := _jar.get_floor_y() - position.y
	draw_dashed_line(Vector2(0, radius + 6.0), Vector2(0, bottom), aim_line_color, 3.0, 14.0)
