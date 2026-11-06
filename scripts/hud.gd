class_name Hud
extends CanvasLayer
## On-screen UI: the settings button and pop-up, the score cloud with the
## evolution chart just under it, the Next monster preview, the power-up
## buttons along the bottom, and the game-over panel.
##
## LAYOUT
## The evolution chart (TierTrack) sits under the score cloud at 80% size: its
## Scale in the Inspector is 0.8. The power-up buttons (PowerUps) sit in a row
## under the jar, where the chart used to be. Move either node in the editor.
##
## The HUD keeps running while the game is paused (process_mode = Always), so
## the settings pop-up works while everything else is frozen.
##
## SETTINGS POP-UP
## The pop-up is one picture (assets/ui/settings_popup.png). Its buttons are
## invisible click areas placed over the picture, sized as fractions of it
## (anchors), so they stay lined up if the picture is resized. To adjust one,
## select it under SettingsPopup/Panel and drag its anchors in the editor.

signal play_again_pressed
## Restart button in the settings pop-up.
signal restart_pressed
## Home button in the settings pop-up. Nothing listens yet: there is no home
## screen so far.
signal home_pressed
## Sound / Music / Vibrate / Effects in the settings pop-up ("sound", "music",
## "vibrate", "effects"). Sound, Music and Vibrate are switched by the HUD
## itself through GameAudio; Effects has no job yet.
signal setting_pressed(setting: String)
## A power-up button ("vanish", "blast", "upgrade"). Nothing listens yet: what
## each power-up does is still to be decided.
signal power_up_pressed(power_up: String)

@onready var _settings_button: TextureButton = $SettingsButton
@onready var _settings_popup: Control = $SettingsPopup
@onready var _settings_panel: Control = $SettingsPopup/Panel
@onready var _power_ups: Control = $PowerUps
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
	_settings_popup.visible = false
	_settings_button.pressed.connect(func() -> void:
		_bounce(_settings_button)
		open_settings())
	_connect_settings_popup()
	for button: TextureButton in _power_ups.get_children():
		var power_up := button.name.to_lower()
		button.pressed.connect(func() -> void:
			_bounce(button)
			power_up_pressed.emit(power_up))


## Shows the settings pop-up and pauses the game underneath it.
func open_settings() -> void:
	get_tree().paused = true
	_settings_popup.visible = true
	_settings_panel.scale = Vector2(0.85, 0.85)
	_settings_panel.create_tween().tween_property(_settings_panel, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Hides the settings pop-up and un-pauses the game.
func close_settings() -> void:
	_settings_popup.visible = false
	get_tree().paused = false


func _connect_settings_popup() -> void:
	var panel := _settings_panel
	(panel.get_node("Close") as TextureButton).pressed.connect(func() -> void:
		GameAudio.play("click")
		close_settings())
	(panel.get_node("Restart") as TextureButton).pressed.connect(func() -> void:
		GameAudio.play("click")
		close_settings()
		restart_pressed.emit())
	(panel.get_node("Home") as TextureButton).pressed.connect(func() -> void:
		GameAudio.play("click")
		home_pressed.emit())
	for setting in ["Sound", "Music", "Vibrate", "Effects"]:
		var key: String = setting.to_lower()
		var button := panel.get_node(setting) as TextureButton
		button.pressed.connect(func() -> void:
			_toggle_setting(key)
			GameAudio.play("click")
			setting_pressed.emit(key))
		if key != "effects":
			button.add_child(_make_off_badge())
	_refresh_toggles()


## Sound, Music and Vibrate switch on/off (saved between games by GameAudio).
## Effects has no job yet.
func _toggle_setting(key: String) -> void:
	match key:
		"sound": GameAudio.set_sound_on(not GameAudio.sound_on)
		"music": GameAudio.set_music_on(not GameAudio.music_on)
		"vibrate": GameAudio.set_vibrate_on(not GameAudio.vibrate_on)
	_refresh_toggles()


## Shows the dark "OFF" cover on each switch that is turned off.
func _refresh_toggles() -> void:
	var states := {"Sound": GameAudio.sound_on, "Music": GameAudio.music_on, "Vibrate": GameAudio.vibrate_on}
	for setting in states:
		_settings_panel.get_node(setting + "/Off").visible = not states[setting]


## A see-through dark rounded cover with "OFF" on it, sized to the blue
## button square in the pop-up art (the top part of the click area).
func _make_off_badge() -> Control:
	var badge := Panel.new()
	badge.name = "Off"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 0.04
	badge.anchor_right = 0.96
	badge.anchor_top = 0.03
	badge.anchor_bottom = 0.7
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.2, 0.6)
	style.set_corner_radius_all(24)
	badge.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "OFF"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_outline_color", Color(0.75, 0.1, 0.2))
	label.add_theme_constant_override("outline_size", 8)
	badge.add_child(label)
	return badge


## Quick squash-and-stretch (and a click sound) so a tap feels like it landed.
func _bounce(control: Control) -> void:
	GameAudio.play("click")
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(0.88, 0.88)
	control.create_tween().tween_property(control, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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


## The evolution chart under the score cloud: a rounded bar showing all 7 monsters
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
