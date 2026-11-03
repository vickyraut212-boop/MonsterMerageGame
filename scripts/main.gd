extends Node2D
## Main game scene. Connects the dropper, the jar and the HUD, and runs the
## merge rule: when two monsters of the same tier touch, both disappear and one
## monster of the next tier appears at their exact midpoint.

const SAVE_PATH := "user://best_score.cfg"

@onready var jar: Jar = $Jar
@onready var dropper: Dropper = $Dropper
@onready var monsters: Node2D = $Monsters
@onready var hud: Hud = $HUD

var score := 0
var best := 0
var _is_over := false


func _ready() -> void:
	randomize()
	_check_sprites()

	best = _load_best()
	hud.set_score(0)
	hud.set_best(best)

	dropper.next_changed.connect(hud.set_next)
	dropper.dropped.connect(_on_dropped)
	jar.game_over.connect(_on_game_over)
	hud.play_again_pressed.connect(_on_play_again)

	dropper.setup(jar)


func _on_dropped(tier: int, at: Vector2) -> void:
	_spawn_monster(tier, at)


func _spawn_monster(tier: int, at: Vector2) -> Monster:
	var monster := Monster.new()
	monster.setup(tier)
	monster.position = at
	monster.touched_same_tier.connect(_on_same_tier_touched)
	monsters.add_child(monster)
	return monster


func _on_same_tier_touched(a: Monster, b: Monster) -> void:
	if _is_over or a.is_merging or b.is_merging:
		return
	a.is_merging = true
	b.is_merging = true
	# Physics bodies can't be removed in the middle of a physics step,
	# so the merge itself runs right after it.
	_merge.call_deferred(a, b)


func _merge(a: Monster, b: Monster) -> void:
	if not is_instance_valid(a) or not is_instance_valid(b):
		return
	var midpoint := (a.global_position + b.global_position) / 2.0
	var velocity := (a.linear_velocity + b.linear_velocity) / 2.0
	var new_tier := a.tier + 1

	for old in [a, b]:
		monsters.remove_child(old)
		old.queue_free()

	if new_tier > TierData.tier_count():
		# Two Tier 7 bosses: both vanish for a big bonus.
		_add_score(TierData.BOSS_MERGE_BONUS)
		_show_points_popup(midpoint, TierData.BOSS_MERGE_BONUS, true)
		return

	var points := TierData.get_points(new_tier)
	var bonus := TierData.get_bonus(new_tier)
	_add_score(points + bonus)
	_show_points_popup(midpoint, points + bonus, bonus > 0)
	var merged := _spawn_monster(new_tier, midpoint)
	merged.linear_velocity = velocity * 0.5
	merged.pop_in()


func _add_score(points: int) -> void:
	score += points
	hud.set_score(score)
	hud.set_best(maxi(best, score))


## Floating "+points" text that rises and fades where a merge happened.
## Gold and bigger when the merge earned a bonus.
func _show_points_popup(at: Vector2, points: int, is_bonus: bool) -> void:
	var label := Label.new()
	label.text = ("+%d BONUS!" if is_bonus else "+%d") % points
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 44 if is_bonus else 30)
	label.add_theme_color_override("font_color",
			Color(1, 0.85, 0.4) if is_bonus else Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.3))
	label.add_theme_constant_override("outline_size", 10)
	label.size = Vector2(320, 60)
	label.position = at - label.size / 2.0
	label.z_index = 10
	add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 80.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func _on_game_over() -> void:
	_is_over = true
	dropper.stop()
	var is_new_best := score > best
	if is_new_best:
		best = score
		_save_best(best)
	hud.show_game_over(score, best, is_new_best)


func _on_play_again() -> void:
	get_tree().reload_current_scene()


func _load_best() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value("score", "best", 0))


func _save_best(value: int) -> void:
	var config := ConfigFile.new()
	config.set_value("score", "best", value)
	config.save(SAVE_PATH)


func _check_sprites() -> void:
	var missing: Array[String] = []
	for tier in range(1, TierData.tier_count() + 1):
		if TierData.get_texture(tier) == null:
			missing.append(TierData.get_tier(tier)["texture"])
	if not missing.is_empty():
		push_warning("Monster Merge: missing sprites: %s" % ", ".join(missing))
