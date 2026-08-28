# Strike Wing '94 QA

## Required smoke tests

1. Project opens in Godot 4.6.2 without import or parse errors.
2. Main scene boots at 640x360 internal resolution.
3. WASD and arrow movement remain inside the playfield.
4. Space creates twin primary shots at the intended cadence.
5. X consumes exactly one bomb and clears current enemies.
6. Enemy bullets/ramming never reduce hull before shield is depleted.
7. Destroyed enemies award score once only.
8. Enemies leaving the bottom of the playfield are removed.
9. Player death resets transient combat state without negative score.
10. JSON files in data/ parse successfully and preserve unique ids.

## Regression gates

- No generated `.godot`, build, cache or export content is committed.
- No GitHub Actions workflow is required for validation.
- Gameplay must remain functional with placeholder art removed/replaced.
- Additions to missions, weapons and enemies should be data-first unless code behavior is genuinely new.
- Never copy proprietary assets, enemy layouts, names, sounds or exact levels from reference games.

## Future automated checks

- deterministic seeded spawn test
- projectile lifetime/leak test
- damage arithmetic test
- campaign economy validation
- duplicate content-id detection
- headless mission completion simulation
