extends RefCounted

const FAMILIES := {
	"atlas_tanker": [preload("res://assets/runtime/support/battlefield/atlas_tanker/0.png"), preload("res://assets/runtime/support/battlefield/atlas_tanker/1.png"), preload("res://assets/runtime/support/battlefield/atlas_tanker/2.png"), preload("res://assets/runtime/support/battlefield/atlas_tanker/3.png")],
	"rapier_fighter": [preload("res://assets/runtime/support/battlefield/rapier_fighter/0.png"), preload("res://assets/runtime/support/battlefield/rapier_fighter/1.png"), preload("res://assets/runtime/support/battlefield/rapier_fighter/2.png"), preload("res://assets/runtime/support/battlefield/rapier_fighter/3.png")],
	"hammer_bomber": [preload("res://assets/runtime/support/battlefield/hammer_bomber/0.png"), preload("res://assets/runtime/support/battlefield/hammer_bomber/1.png"), preload("res://assets/runtime/support/battlefield/hammer_bomber/2.png"), preload("res://assets/runtime/support/battlefield/hammer_bomber/3.png")],
	"spectre_gunship": [preload("res://assets/runtime/support/battlefield/spectre_gunship/0.png"), preload("res://assets/runtime/support/battlefield/spectre_gunship/1.png"), preload("res://assets/runtime/support/battlefield/spectre_gunship/2.png"), preload("res://assets/runtime/support/battlefield/spectre_gunship/3.png")],
}

static func frame_for_clock(family: String, clock: float, fps: float = 8.0) -> Texture2D:
	var frames: Array = FAMILIES.get(family, [])
	if frames.is_empty():
		return null
	return frames[int(floor(clock * fps)) % frames.size()]
