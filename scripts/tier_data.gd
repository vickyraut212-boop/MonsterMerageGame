extends Node
## Monster tier settings. This is the one file to edit when tuning monsters.
## It is loaded automatically as "TierData", so any script can use it.
##
## For each tier:
##   name     - a label, used only in messages
##   texture  - the PNG in assets/monsters
##   radius   - collision circle size in pixels (the sprite is scaled to fit).
##              PLACEHOLDER values: to be replaced with the art size chart.
##   points   - score for creating this tier by merging

const TIERS: Array[Dictionary] = [
	{"name": "Tier 1 - Tiny Dot",  "texture": "res://assets/monsters/tier_1.png", "radius": 20.0,  "points": 1},
	{"name": "Tier 2",             "texture": "res://assets/monsters/tier_2.png", "radius": 30.0,  "points": 3},
	{"name": "Tier 3",             "texture": "res://assets/monsters/tier_3.png", "radius": 42.0,  "points": 6},
	{"name": "Tier 4",             "texture": "res://assets/monsters/tier_4.png", "radius": 56.0,  "points": 10},
	{"name": "Tier 5",             "texture": "res://assets/monsters/tier_5.png", "radius": 72.0,  "points": 15},
	{"name": "Tier 6",             "texture": "res://assets/monsters/tier_6.png", "radius": 92.0,  "points": 21},
	{"name": "Tier 7 - Big Boss",  "texture": "res://assets/monsters/tier_7.png", "radius": 115.0, "points": 28},
]

## The dropper only ever hands out tiers 1 up to this one.
const MAX_DROP_TIER := 3

## Bonus for merging two Tier 7 bosses (they vanish).
const BOSS_MERGE_BONUS := 100


func tier_count() -> int:
	return TIERS.size()


func is_valid(tier: int) -> bool:
	return tier >= 1 and tier <= TIERS.size()


func get_tier(tier: int) -> Dictionary:
	assert(is_valid(tier), "Tier %d does not exist" % tier)
	return TIERS[tier - 1]


func get_radius(tier: int) -> float:
	return get_tier(tier)["radius"]


func get_points(tier: int) -> int:
	return get_tier(tier)["points"]


## Returns the tier's sprite, or null if the PNG is missing.
func get_texture(tier: int) -> Texture2D:
	var path: String = get_tier(tier)["texture"]
	if ResourceLoader.exists(path):
		return load(path)
	return null


## A random tier the dropper can hand out (1 to MAX_DROP_TIER).
func random_drop_tier() -> int:
	return randi_range(1, MAX_DROP_TIER)
