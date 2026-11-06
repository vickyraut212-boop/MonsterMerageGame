class_name SpaceBackground
extends Node2D
## The space backdrop behind everything: the background painting plus a few
## planets and stars scattered at random each game.
##
## PURELY DECORATIVE: nothing here has a collision shape, it is drawn behind
## every other node (z_index -100), and the planets/stars are never placed
## over the jar or over the HUD areas listed in keep_clear.

## The background painting. It is scaled to cover the whole 720 x 1280 screen.
@export var background_texture: Texture2D = preload("res://assets/ui/background.jpg")

@export_group("Planets and stars")
## Pictures to scatter. One is picked at random for each piece.
@export var planet_textures: Array[Texture2D] = [preload("res://assets/ui/planet.png")]
@export var star_textures: Array[Texture2D] = [
	preload("res://assets/ui/star_1.png"),
	preload("res://assets/ui/star_2.png"),
	preload("res://assets/ui/star_3.png"),
]
@export var planet_count := 2
@export var star_count := 9
## Size range, in screen pixels (width of the picture).
@export var planet_size := Vector2(64.0, 88.0)
@export var star_size := Vector2(18.0, 34.0)
## How see-through the decorations are (1 = solid), so they stay in the background.
@export_range(0.0, 1.0) var decor_opacity := 0.75
## Screen areas that must stay empty (score, buttons, evolution track).
## The jar and the space above it (where the ship flies) are added automatically.
@export var keep_clear: Array[Rect2] = [
	Rect2(0, 0, 720, 270),       # top bar: settings, score cloud, Next, power-ups
	Rect2(0, 1090, 720, 190),    # evolution track along the bottom
]
## Extra space kept free around the jar.
@export var jar_margin := 10.0

const SCREEN := Vector2(720, 1280)


func _ready() -> void:
	z_index = -100
	z_as_relative = false
	var jar := get_parent().get_node_or_null("Jar") as Jar
	var blocked := keep_clear.duplicate()
	if jar:
		var t := jar.wall_thickness
		var inner := jar.get_inner_rect()
		# The jar plus the column above it where the ship flies and aims.
		var bottom := inner.end.y + t
		blocked.append(Rect2(inner.position.x - t, 0.0, inner.size.x + t * 2.0, bottom).grow(jar_margin))
	var placed: Array[Rect2] = []
	_scatter(planet_textures, planet_count, planet_size, blocked, placed, true)
	_scatter(star_textures, star_count, star_size, blocked, placed, false)


func _draw() -> void:
	if background_texture == null:
		return
	# Cover the screen without stretching: scale to the larger ratio and centre.
	var tex := background_texture.get_size()
	var s := maxf(SCREEN.x / tex.x, SCREEN.y / tex.y)
	var size := tex * s
	draw_texture_rect(background_texture, Rect2((SCREEN - size) / 2.0, size), false)


## Places up to `count` pictures in free spots. Each is a plain Sprite2D, with
## a slow bob (planets) or twinkle (stars).
func _scatter(textures: Array[Texture2D], count: int, size_range: Vector2,
		blocked: Array, placed: Array[Rect2], is_planet: bool) -> void:
	if textures.is_empty():
		return
	for i in count:
		var tex: Texture2D = textures.pick_random()
		var width := randf_range(size_range.x, size_range.y)
		var size := tex.get_size() * (width / tex.get_size().x)
		var spot := _find_spot(size, blocked, placed)
		if spot == Rect2():
			continue  # no room left; skip rather than overlap the game
		placed.append(spot.grow(12.0))

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = Vector2.ONE * (width / tex.get_size().x)
		sprite.position = spot.get_center()
		sprite.rotation = randf_range(-0.3, 0.3)
		sprite.modulate.a = decor_opacity
		add_child(sprite)
		_animate(sprite, is_planet)


func _find_spot(size: Vector2, blocked: Array, placed: Array[Rect2]) -> Rect2:
	for attempt in 60:
		var pos := Vector2(randf_range(0.0, SCREEN.x - size.x), randf_range(0.0, SCREEN.y - size.y))
		var rect := Rect2(pos, size)
		var ok := true
		for other in blocked + placed:
			if rect.intersects(other):
				ok = false
				break
		if ok:
			return rect
	return Rect2()


func _animate(sprite: Sprite2D, is_planet: bool) -> void:
	var tween := sprite.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_planet:
		var y := sprite.position.y
		var period := randf_range(3.0, 5.0)
		tween.tween_property(sprite, "position:y", y - 6.0, period)
		tween.tween_property(sprite, "position:y", y + 6.0, period)
	else:
		var base := sprite.scale
		var period := randf_range(0.8, 1.6)
		tween.tween_interval(randf_range(0.0, 1.5))
		tween.tween_property(sprite, "scale", base * 0.75, period)
		tween.tween_property(sprite, "scale", base, period)
