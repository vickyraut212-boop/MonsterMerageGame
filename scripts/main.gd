extends Node2D
## Main game scene. For now it only checks that all 7 monster sprites are in place.
## Later steps add the jar, the dropper and the merge logic here.


func _ready() -> void:
	randomize()
	_check_sprites()


func _check_sprites() -> void:
	var missing: Array[String] = []
	for tier in range(1, TierData.tier_count() + 1):
		if TierData.get_texture(tier) == null:
			missing.append(TierData.get_tier(tier)["texture"])
	if missing.is_empty():
		print("Monster Merge: all %d monster sprites found." % TierData.tier_count())
	else:
		push_warning("Monster Merge: missing sprites: %s" % ", ".join(missing))
