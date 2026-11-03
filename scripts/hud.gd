class_name Hud
extends CanvasLayer
## On-screen UI: score, best score, the Next monster preview, the tier strip
## along the bottom, and the game-over panel.

signal play_again_pressed

@onready var _score_label: Label = $ScorePanel/ScoreLabel
@onready var _best_label: Label = $ScorePanel/BestLabel
@onready var _next_icon: TextureRect = $NextPanel/NextIcon
@onready var _tier_strip: HBoxContainer = $TierStrip
@onready var _game_over: Control = $GameOver
@onready var _final_score_label: Label = $GameOver/Box/FinalScore
@onready var _final_best_label: Label = $GameOver/Box/FinalBest
@onready var _play_again_button: Button = $GameOver/Box/PlayAgain


func _ready() -> void:
	_game_over.visible = false
	_build_tier_strip()
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


## A row of all 7 monsters, smallest to biggest, so players see the merge chain.
func _build_tier_strip() -> void:
	for tier in range(1, TierData.tier_count() + 1):
		var icon := TextureRect.new()
		icon.texture = TierData.get_texture(tier)
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tier_strip.add_child(icon)
