class_name PlayerMountRules
extends RefCounted

const FIGHTER := "fighter"
const BOMBER := "bomber"

static func sanitize_form(form: String) -> String:
	return BOMBER if form == BOMBER else FIGHTER

static func offset_for_mount(mount: Dictionary, form: String) -> Vector2:
	var safe_form := sanitize_form(form)
	var key := "%s_offset" % safe_form
	var raw = mount.get(key, [0, 0])
	if typeof(raw) != TYPE_ARRAY or raw.size() < 2:
		return Vector2.ZERO
	return Vector2(roundf(float(raw[0])), roundf(float(raw[1])))

static func mounts_for_role(mounts: Array, form: String, role: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var safe_form := sanitize_form(form)
	for value in mounts:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var mount: Dictionary = value
		var forms = mount.get("forms", [])
		var roles = mount.get("roles", [])
		if typeof(forms) != TYPE_ARRAY or safe_form not in forms:
			continue
		if typeof(roles) != TYPE_ARRAY or role not in roles:
			continue
		result.append(mount)
	return result

static func primary_role(weapon: Dictionary, form: String) -> String:
	var archetype := str(weapon.get("archetype", "balanced"))
	if archetype == "precision_kinetic": return "rail"
	if archetype == "directed_energy_pulse": return "directed_energy"
	if archetype == "strategic_plasma": return "plasma"
	return "ballistic_primary"

static func primary_offsets(mounts: Array, form: String, weapon: Dictionary, projectile_count: int) -> Array[Vector2]:
	var count := maxi(1, projectile_count)
	var safe_form := sanitize_form(form)
	var role := primary_role(weapon, safe_form)
	var candidates := mounts_for_role(mounts, safe_form, role)
	var result: Array[Vector2] = []
	if candidates.is_empty():
		for _i in range(count): result.append(Vector2(0, -18))
		return result
	if candidates.size() == 1:
		var point := offset_for_mount(candidates[0], safe_form)
		for _i in range(count): result.append(point)
		return result
	for i in range(count):
		result.append(offset_for_mount(candidates[i % candidates.size()], safe_form))
	return result

static func support_role(support: Dictionary) -> String:
	var support_id := str(support.get("id", ""))
	if bool(support.get("strategic", false)) or support_id == "micro_warhead_rack": return "strategic_store"
	match str(support.get("type", "")):
		"rockets": return "rocket"
		"hunter": return "missile"
		"crossfire": return "rocket"
	return ""

static func support_offsets(mounts: Array, form: String, support: Dictionary, projectile_count: int, alternating_side: bool = false) -> Array[Vector2]:
	var count := maxi(1, projectile_count)
	var safe_form := sanitize_form(form)
	var role := support_role(support)
	var candidates := mounts_for_role(mounts, safe_form, role)
	var result: Array[Vector2] = []
	if candidates.is_empty():
		for _i in range(count): result.append(Vector2(0, -10))
		return result
	if count == 1:
		var index := 0
		if candidates.size() > 1 and alternating_side: index = 1
		result.append(offset_for_mount(candidates[index], safe_form))
		return result
	for i in range(count): result.append(offset_for_mount(candidates[i % candidates.size()], safe_form))
	return result

static func bomber_rotary_deployed(form: String, weapon: Dictionary) -> bool:
	if sanitize_form(form) != BOMBER: return false
	return primary_role(weapon, BOMBER) == "ballistic_primary"
