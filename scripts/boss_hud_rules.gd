class_name BossHudRules
extends RefCounted

static func health_ratio(hp: int, max_hp: int) -> float:
	return clampf(float(maxi(0, hp)) / float(maxi(1, max_hp)), 0.0, 1.0)

static func boss_name(id: String) -> String:
	return id.replace("_", " ").to_upper() if id != "" else "BOSS"

static func phase_label(phase: int) -> String:
	var safe_phase := clampi(phase, 1, 3)
	match safe_phase:
		1:
			return "PHASE 1  ATTACK PATTERN"
		2:
			return "PHASE 2  ESCALATION"
		3:
			return "PHASE 3  WEAK POINT EXPOSED"
	return "PHASE %d" % safe_phase

static func hud_text(id: String, hp: int, max_hp: int, phase: int) -> String:
	return "%s  %s  %d/%d" % [boss_name(id), phase_label(phase), maxi(0, hp), maxi(1, max_hp)]
