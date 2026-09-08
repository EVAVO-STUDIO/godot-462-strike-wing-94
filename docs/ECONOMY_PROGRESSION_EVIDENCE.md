# HYPERSONIC Economy and Progression Evidence

Status: release-candidate evidence contract under feature freeze.

The economy audit exists to prevent a technically complete campaign from shipping with a progression wall, repair spiral or accidental always-buy-one-thing path. It does **not** authorize balance changes from static maths alone.

## Authorities

- `data/campaign.json` owns starting credits, service prices and fixed progression bonuses.
- `data/weapons.json`, `data/generators.json`, `data/airframes.json` and `data/support_systems.json` own priced progression catalogues.
- `data/difficulty_profiles.json` owns reward multipliers.
- `scripts/progression_rules.gd`, `scripts/reward_rules.gd`, `scripts/objective_rules.gd` and `scripts/service_rules.gd` own runtime arithmetic.
- `tools/economy_progression_self_test.gd` proves the runtime arithmetic remains aligned with the authored data.
- `tools/run_economy_progression_audit.ps1` produces exact-SHA conservative affordability evidence in ignored `work/economy/`.

## Conservative opening guardrail

For each campaign difficulty, the audit models:

`starting credits + guaranteed Mission 1 zero-score fixed reward - worst survivable full service on the starting airframe`

Worst survivable full service means one hull point remaining and an empty shield. The audit requires that wallet to retain at least one major progression purchase path from primary weapons, generators, airframes or tactical support.

This deliberately models an unusually expensive successful first sortie. It is a regression guard, not a target player outcome.

## Mission reward rows

For every one of the 30 canonical campaign missions the report records:

- required-objective fixed bonuses;
- all authored objective bonuses;
- boss bonus when boss destruction is a required success condition;
- zero-score fixed reward before difficulty scaling;
- the corresponding Cadet, Combat, Veteran and Ace reward values.

Score-derived credits remain excluded from the conservative floor because real score depends on actual play.

## Service liability

The report records near-loss full-service liability for every airframe tier. Higher-capacity frames naturally create a larger absolute repair/recharge ceiling; this is evidence for human review, not justification to flatten their costs automatically.

## Truth boundary

Do not infer any of the following from the static audit alone:

- that a normal player earns the zero-score floor;
- that a normal player reaches every optional objective;
- that a weapon is fun or dominant;
- that a higher difficulty's reward multiplier correctly compensates for its pressure;
- that repeated repair bills feel fair across a complete campaign;
- that late-game purchases arrive at the right dramatic moment.

Those require vulnerable completed-sortie evidence and human campaign review.

Never auto-tune rewards, prices, repair rates or equipment from one deterministic bot run or from the conservative affordability model. Use the audit to detect regressions and identify hypotheses for human playtesting.

## Release command

The complete Windows release gate runs the economy audit automatically:

```powershell
.\tools\validate_windows_release.ps1
```

Using `-SkipEconomyAudit` makes the run diagnostic only and prevents issuance of the exact-SHA release receipt.
