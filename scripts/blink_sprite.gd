class_name BlinkSprite
extends Sprite2D
## A monster sprite that blinks now and then while idle.
## Call set_tier(tier) to show a tier; it then plays the tier's blink frames
## (assets/monsters/tier_N_blink_1..3.png) at random intervals.
## If a tier has no blink frames it simply shows the still sprite.

## Seconds between blinks (picked at random in this range).
const BLINK_GAP_MIN := 2.5
const BLINK_GAP_MAX := 6.0
## How long each blink frame shows: half-closed, closed, half-open.
const FRAME_TIMES: Array[float] = [0.05, 0.08, 0.05]
## Chance of a quick double blink.
const DOUBLE_BLINK_CHANCE := 0.2

var _open: Texture2D
var _frames: Array[Texture2D] = []
var _wait := 0.0
var _frame := -1  # -1 = eyes open
var _frame_left := 0.0
var _blinks_left := 0


func set_tier(tier: int) -> void:
	_open = TierData.get_texture(tier)
	_frames = TierData.get_blink_frames(tier)
	texture = _open
	scale = TierData.get_sprite_scale(tier)
	_frame = -1
	# Random start so monsters in the jar don't all blink together.
	_wait = randf_range(0.5, BLINK_GAP_MAX)


func _process(delta: float) -> void:
	if _frames.is_empty():
		return
	if _frame < 0:
		_wait -= delta
		if _wait <= 0.0:
			_blinks_left = 2 if randf() < DOUBLE_BLINK_CHANCE else 1
			_show_frame(0)
		return
	_frame_left -= delta
	if _frame_left > 0.0:
		return
	if _frame + 1 < _frames.size():
		_show_frame(_frame + 1)
		return
	# Blink finished: eyes open again.
	_blinks_left -= 1
	_frame = -1
	texture = _open
	_wait = 0.12 if _blinks_left > 0 else randf_range(BLINK_GAP_MIN, BLINK_GAP_MAX)


func _show_frame(i: int) -> void:
	_frame = i
	_frame_left = FRAME_TIMES[mini(i, FRAME_TIMES.size() - 1)]
	texture = _frames[i]
