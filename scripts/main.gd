extends Node2D
## Main game scene: holds the jar and (for now) a simple test drop.
##
## TEST DROP: click or tap anywhere to drop a random Tier 1-3 monster at that
## spot, so you can see the walls, floor and danger line working.
## Step 3 replaces this with the real dropper.

@onready var jar: Jar = $Jar
@onready var game_over_label: Label = $GameOverLabel

var _is_over := false


func _ready() -> void:
	randomize()
	_check_sprites()
	jar.game_over.connect(_on_game_over)


func _unhandled_input(event: InputEvent) -> void:
	if _is_over:
		return
	# A tap on a phone also arrives as a left mouse click.
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_drop_test_monster(click.position.x)


func _drop_test_monster(x: float) -> void:
	var tier := TierData.random_drop_tier()
	var radius := TierData.get_radius(tier)

	var monster := RigidBody2D.new()
	monster.add_to_group("monsters")

	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	monster.add_child(collider)

	var sprite := Sprite2D.new()
	sprite.texture = TierData.get_texture(tier)
	sprite.scale = TierData.get_sprite_scale(tier)
	monster.add_child(sprite)

	# Keep the drop inside the jar, just above the rim.
	var inner := jar.get_inner_rect()
	monster.position = Vector2(
			clampf(x, inner.position.x + radius, inner.end.x - radius),
			inner.position.y - 120.0)
	add_child(monster)


func _on_game_over() -> void:
	_is_over = true
	game_over_label.visible = true
	print("Monster Merge: game over")


func _check_sprites() -> void:
	var missing: Array[String] = []
	for tier in range(1, TierData.tier_count() + 1):
		if TierData.get_texture(tier) == null:
			missing.append(TierData.get_tier(tier)["texture"])
	if missing.is_empty():
		print("Monster Merge: all %d monster sprites found." % TierData.tier_count())
	else:
		push_warning("Monster Merge: missing sprites: %s" % ", ".join(missing))
