class_name SpaceBackground
extends Node2D
## The space backdrop behind everything: the background painting plus planets
## and stars scattered at random each game.
##
## LAYOUT (following vicky's reference)
## - All the planets appear every game, each hugging a different screen edge,
##   big and partly cropped off-screen, in varied sizes. One always sits in
##   the top-right corner, just under the right power-up.
## - A few small stars sit in the open space that is left.
##
## PURELY DECORATIVE: nothing here has a collision shape, everything is drawn
## behind every other node (z_index -100), and nothing is ever placed over the
## jar, the space above it where the ship flies, the score cloud, the Next
## preview, the settings and power-up buttons or the evolution track.

## The background painting. It is scaled to cover the whole 720 x 1280 screen.
@export var background_texture: Texture2D = preload("res://assets/ui/background.jpg")

@export_group("Planets")
@export var planet_textures: Array[Texture2D] = [
	preload("res://assets/ui/planet_1.png"),
	preload("res://assets/ui/planet_2.png"),
	preload("res://assets/ui/planet_3.png"),
]
## Planet width range, in screen pixels (before cropping by the screen edge).
@export var planet_size := Vector2(170.0, 270.0)
## How much of each planet may hang off-screen (0.5 = up to half of it).
@export_range(0.0, 0.8) var planet_max_offscreen := 0.6
@export_range(0.0, 1.0) var planet_opacity := 0.9

@export_group("Stars")
@export var star_textures: Array[Texture2D] = [
	preload("res://assets/ui/star_1.png"),
	preload("res://assets/ui/star_2.png"),
]
@export var star_count := 5
## Star width range, in screen pixels.
@export var star_size := Vector2(22.0, 40.0)
@export_range(0.0, 1.0) var star_opacity := 0.9

@export_group("Keep clear")
## Areas planets must not cover (score cloud, Next preview, top buttons,
## evolution track).
## The jar and the column above it are added automatically.
@export var planet_keep_clear: Array[Rect2] = [
	Rect2(200, 0, 320, 175),     # score cloud
	Rect2(560, 0, 160, 145),     # Next preview (see-through panel)
	Rect2(0, 0, 215, 245),       # settings button and left power-ups
	Rect2(600, 140, 120, 105),   # right power-up
	Rect2(100, 1085, 520, 165),  # evolution track
]
## Areas stars must not cover (the whole top bar and the evolution track).
@export var star_keep_clear: Array[Rect2] = [
	Rect2(0, 0, 720, 250),
	Rect2(0, 1085, 720, 195),
]
## Extra space kept free around the jar.
@export var jar_margin := 10.0
## Where the jar's protected column starts; above this only the score cloud is
## in the middle of the screen.
@export var column_top := 175.0

const SCREEN := Vector2(720, 1280)
## Planets never get smaller than this (radius), so none shows as a sliver;
## if one can't fit at a spot, another spot is tried.
const MIN_PLANET_RADIUS := 60.0

## Edge spots a planet can hug: a point on (or just past) the screen edge,
## and how far along that edge it may slide (as a fraction of the screen).
const EDGE_SPOTS := [
	# Always used first: vicky wants one planet in the top-right corner.
	{"name": "right_corner", "at": Vector2(1.0, 0.27), "slide": Vector2(0.0, 0.03)},
	{"name": "left_high", "at": Vector2(0.0, 0.38), "slide": Vector2(0.0, 0.1)},
	{"name": "left_low", "at": Vector2(0.0, 0.72), "slide": Vector2(0.0, 0.1)},
	{"name": "right_high", "at": Vector2(1.0, 0.4), "slide": Vector2(0.0, 0.1)},
	{"name": "right_low", "at": Vector2(1.0, 0.7), "slide": Vector2(0.0, 0.1)},
]


func _ready() -> void:
	z_index = -100
	z_as_relative = false
	var jar_rect := Rect2()
	var jar := get_parent().get_node_or_null("Jar") as Jar
	if jar:
		var t := jar.wall_thickness
		var inner := jar.get_inner_rect()
		jar_rect = Rect2(inner.position.x - t, 0.0, inner.size.x + t * 2.0, inner.end.y + t).grow(jar_margin)

	var planet_blocked: Array[Rect2] = planet_keep_clear.duplicate()
	var star_blocked: Array[Rect2] = star_keep_clear.duplicate()
	if jar_rect != Rect2():
		star_blocked.append(jar_rect)
		var column := jar_rect
		column.position.y = column_top
		column.size.y = jar_rect.end.y - column_top
		planet_blocked.append(column)

	var planets := _place_planets(planet_blocked)
	_place_stars(star_blocked, planets)


func _draw() -> void:
	if background_texture == null:
		return
	# Cover the screen without stretching: scale to the larger ratio and centre.
	var tex := background_texture.get_size()
	var s := maxf(SCREEN.x / tex.x, SCREEN.y / tex.y)
	var size := tex * s
	draw_texture_rect(background_texture, Rect2((SCREEN - size) / 2.0, size), false)


## Puts every planet on its own randomly chosen edge spot. Returns the circles
## (Vector3: x, y, radius) they cover, so stars can avoid them.
func _place_planets(blocked: Array[Rect2]) -> Array[Vector3]:
	var circles: Array[Vector3] = []
	var spots := EDGE_SPOTS.slice(1)
	spots.shuffle()
	spots.push_front(EDGE_SPOTS[0])
	var textures := planet_textures.duplicate()
	textures.shuffle()
	for tex: Texture2D in textures:
		var placed := false
		for spot in spots:
			var circle := _fit_planet(spot, blocked, circles)
			if circle == Vector3.ZERO:
				continue
			spots.erase(spot)
			circles.append(circle)
			_add_sprite(tex, Vector2(circle.x, circle.y), circle.z * 2.0, planet_opacity, true)
			placed = true
			break
		if not placed:
			push_warning("SpaceBackground: no room for a planet this game")
	return circles


## Tries random sizes and positions around one edge spot. Returns the planet
## circle, or Vector3.ZERO if nothing fits there.
func _fit_planet(spot: Dictionary, blocked: Array[Rect2], others: Array[Vector3]) -> Vector3:
	var at: Vector2 = spot["at"]
	var slide: Vector2 = spot["slide"]
	for attempt in 40:
		# Later attempts try smaller planets so one always fits.
		var shrink := 1.0 - attempt / 60.0
		var r := maxf(randf_range(planet_size.x, planet_size.y) * shrink / 2.0, MIN_PLANET_RADIUS)
		var off := randf_range(0.1, planet_max_offscreen)  # share hanging off-screen
		var base := at * SCREEN + Vector2(randf_range(-1.0, 1.0) * slide.x, randf_range(-1.0, 1.0) * slide.y) * SCREEN
		var center := base
		# Push the centre inwards from whichever edges the spot is on.
		if at.x == 0.0: center.x = r * (1.0 - 2.0 * off)
		elif at.x == 1.0: center.x = SCREEN.x - r * (1.0 - 2.0 * off)
		if at.y == 0.0: center.y = r * (1.0 - 2.0 * off)
		elif at.y == 1.0: center.y = SCREEN.y - r * (1.0 - 2.0 * off)
		if _circle_is_free(center, r, blocked, others):
			return Vector3(center.x, center.y, r)
	return Vector3.ZERO


func _circle_is_free(center: Vector2, r: float, blocked: Array[Rect2], others: Array[Vector3]) -> bool:
	for rect in blocked:
		var nearest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
		if nearest.distance_to(center) < r:
			return false
	for other in others:
		if center.distance_to(Vector2(other.x, other.y)) < r + other.z + 10.0:
			return false
	return true


## A few small stars in the open space left over.
func _place_stars(blocked: Array[Rect2], planets: Array[Vector3]) -> void:
	if star_textures.is_empty():
		return
	# Everything a star must keep away from, padded so they don't bunch up.
	var taken: Array[Vector3] = []
	for c in planets:
		taken.append(Vector3(c.x, c.y, c.z + 30.0))
	for i in star_count:
		var width := randf_range(star_size.x, star_size.y)
		var r := width / 2.0
		for attempt in 60:
			var center := Vector2(randf_range(r, SCREEN.x - r), randf_range(r, SCREEN.y - r))
			if _circle_is_free(center, r, blocked, taken):
				taken.append(Vector3(center.x, center.y, r + 60.0))
				_add_sprite(star_textures.pick_random(), center, width, star_opacity, false)
				break


func _add_sprite(tex: Texture2D, center: Vector2, width: float, opacity: float, is_planet: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * (width / maxf(tex.get_size().x, tex.get_size().y))
	sprite.position = center
	sprite.rotation = randf_range(-0.35, 0.35)
	sprite.modulate.a = opacity
	add_child(sprite)
	_animate(sprite, is_planet)


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
