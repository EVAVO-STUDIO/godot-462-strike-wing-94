class_name InterceptRouteRules
extends RefCounted

const CHAIN_SECONDS := 2.4
const MAX_CHAIN := 6

static func next_chain(current: int, timer: float, confirmed_kill: bool) -> int:
	if not confirmed_kill:
		return clampi(current, 0, MAX_CHAIN)
	if timer <= 0.0:
		return 1
	return clampi(current + 1, 1, MAX_CHAIN)

static func next_timer(confirmed_kill: bool) -> float:
	return CHAIN_SECONDS if confirmed_kill else 0.0

static func active(chain: int, timer: float) -> bool:
	return chain > 0 and timer > 0.0

static func label(chain: int) -> String:
	var safe := clampi(chain, 1, MAX_CHAIN)
	return "INTERCEPT CHAIN X%d" % safe

static func likely_destroyed(previous_position: Vector2, score_delta: int) -> bool:
	return score_delta > 0 and previous_position.y < 332.0
