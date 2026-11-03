class_name Hud
extends CanvasLayer
## On-screen UI: score, best score, the Next monster preview, the tier strip
## along the bottom, and the game-over panel.

signal play_again_pressed

@onready var _score_label: Label = $ScorePanel/ScoreLabel
@onready var _best_label: Label = $ScorePanel/BestLabel
@onready var _next_icon: TextureRect = $NextPanel/NextIcon
@onready var _tier_track: HBoxContainer = $TierTrack
@onready var _game_over: Control = $GameOver
@onready var _final_score_label: Label = $GameOver/Box/FinalScore
@onready var _final_best_label: Label = $GameOver/Box/FinalBest
@onready var _play_again_button: Button = $GameOver/Box/PlayAgain


func _ready() -> void:
	_game_over.visible = false
	_build_tier_track()
	_play_again_button.pressed.connect(func() -> void: play_again_pressed.emit())


func set_score(score: int) -> void:
	_score_label.text = str(score)
	# Little bounce on the number when it changes.
	_score_label.pivot_offset = _score_label.size / 2.0
	_score_label.scale = Vector2(1.2, 1.2)
	create_tween().tween_property(_score_label, "scale", Vector2.ONE, 0.15)


func set_best(best: int) -> void:
	_best_label.text = "BEST %d" % best


func set_next(tier: int) -> void:
	_next_icon.texture = TierData.get_texture(tier)


func show_game_over(score: int, best: int, is_new_best: bool) -> void:
	_final_score_label.text = "Score: %d" % score
	_final_best_label.text = ("New best!" if is_new_best else "Best: %d" % best)
	_game_over.visible = true


## Icon sizes on the evolution track: Tier 1 is TRACK_SMALL_ICON px and each
## tier steps up evenly to TRACK_BIG_ICON px for Tier 7. Even steps keep every
## monster readable while still showing the order from small to big.
const TRACK_SMALL_ICON := 34.0
const TRACK_BIG_ICON := 68.0
const BADGE_HEIGHT := 26.0

const TRACK_BG := Color(1, 1, 1, 0.09)
const TRACK_BORDER := Color(1, 1, 1, 0.22)
const COIN_COLOR := Color(1.0, 0.8, 0.25)
const COIN_BORDER := Color(0.45, 0.25, 0.05)
const COIN_TEXT := Color(0.3, 0.15, 0.05)


## Puts the evolution track just under the jar (called by main.gd).
func set_track_top(y: float) -> void:
	_tier_track.position.y = y


## The evolution track along the bottom: a rounded bar showing all 7 monsters
## in merge order, smallest to biggest, standing on one baseline, with a gold
## coin under each tier that pays a bonus.
func _build_tier_track() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = TRACK_BG
	style.border_color = TRACK_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(36)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	_tier_track.add_child(panel)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var count := TierData.tier_count()
	for tier in range(1, count + 1):
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.alignment = BoxContainer.ALIGNMENT_END
		column.add_theme_constant_override("separation", 4)
		row.add_child(column)

		var side := lerpf(TRACK_SMALL_ICON, TRACK_BIG_ICON, float(tier - 1) / (count - 1))
		var icon := TextureRect.new()
		icon.texture = TierData.get_texture(tier)
		icon.custom_minimum_size = Vector2(side, side)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(icon)

		var bonus := TierData.get_bonus(tier)
		if bonus > 0:
			column.add_child(_make_coin(bonus))
		else:
			# Empty space the same height as a coin keeps all icons on one line.
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, BADGE_HEIGHT)
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(spacer)


func _make_coin(bonus: int) -> Control:
	var coin := PanelContainer.new()
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.custom_minimum_size = Vector2(44, BADGE_HEIGHT)
	coin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = COIN_COLOR
	style.border_color = COIN_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.content_margin_left = 6
	style.content_margin_right = 6
	coin.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "+%d" % bonus
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COIN_TEXT)
	coin.add_child(label)
	return coin
