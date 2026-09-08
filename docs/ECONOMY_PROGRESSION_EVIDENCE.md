# HYPERSONIC Economy and Progression Evidence

Status: release-candidate evidence contract under feature freeze.

The economy evidence exists to prevent a technically complete campaign from shipping with a progression wall, repair spiral, economically predetermined branch choice or accidental always-buy-one-thing path. It does **not** authorize balance changes from static maths alone.

## Authorities

- `data/campaign.json` owns starting credits, service prices, fixed progression bonuses and branch-credit awards.
- `data/weapons.json`, `data/generators.json`, `data/airframes.json` and `data/support_systems.json` own priced progression catalogues.
- `data/campaign_world.json` owns each mission's technology era.
- `data/difficulty_profiles.json` owns reward multipliers.
- `scripts/progression_rules.gd`, `scripts/reward_rules.gd`, `scripts/objective_rules.gd` and `scripts/service_rules.gd` own runtime arithmetic.
- `CraftFormDirector` publishes the active mission tech era into `ProgressionRules`, keeping the UI/director tech check and the sequential purchase helper synchronized.
- `tools/economy_progression_self_test.gd` proves the runtime arithmetic remains aligned with the authored data.
- `tools/run_economy_progression_audit.ps1` produces exact-SHA conservative affordability evidence in ignored `work/economy/`.
- `tools/run_route_progression_projection.ps1` projects all eight governed branch routes across all four campaign difficulties.
- `tools/analyze_branch_economic_dominance.ps1` isolates each branch choice with matched-route comparisons so route economics are not judged from unrelated campaigns.

## Sequential ownership model

Primary weapons, generators, airframes and tactical support are four independent sequential ladders. A later tier's sticker price is not its fresh-campaign acquisition cost: every preceding paid tier in that family must be acquired first.

The economy report therefore records both:

- `sticker_cost` for that individual tier;
- `cumulative_acquisition_cost` for reaching that tier from the fresh-campaign family state.

It also marks the four `next_purchases_from_fresh`, one per progression family. The opening affordability guard is evaluated against those actual next choices rather than against arbitrary later catalogue rows.

Owned primary weapons remain selectable after purchase, so sequential acquisition does not mean the latest primary permanently erases earlier specialist loadouts.

## Conservative opening guardrail

For each campaign difficulty, the audit models:

`starting credits + guaranteed Mission 1 zero-score fixed reward - worst survivable full service on the starting airframe`

Worst survivable full service means one hull point remaining and an empty shield. The audit requires that wallet to retain at least one **actually next-purchasable** major progression option.

This deliberately models an unusually expensive successful first sortie. It is a regression guard, not a target player outcome.

## Mission reward rows

For every one of the 30 canonical campaign missions the report records:

- required-objective fixed bonuses;
- all authored objective bonuses;
- boss bonus when boss destruction is a required success condition;
- zero-score fixed reward before difficulty scaling;
- the corresponding Cadet, Combat, Veteran and Ace reward values.

Score-derived credits remain excluded from the conservative floor because real score depends on actual play.

## Eight-route progression projection

The campaign contains three controlled binary branch decisions, so the governed campaign matrix contains eight routes. Each real branch route has 27 sorties.

`run_route_progression_projection.ps1` combines the economy report with the authoritative campaign and mission-tech context and produces 32 projections:

- 8 branch routes;
- 4 difficulties;
- 27 sorties per route.

For every projection it starts at the authored 2,500-credit reserve and assumes:

- zero score;
- guaranteed fixed success rewards only;
- the selected branch bonus when a branch is committed;
- worst-survivable full service on the **starting** airframe after every successful sortie.

Each progression family is then evaluated independently. For every paid tier the projection asks when its cumulative acquisition cost is both financially reachable and legal under the active mission tech era.

This is intentionally harsh. A tier that remains unreachable under this model becomes a review signal, not an automatic price reduction. Conversely, a tier appearing early in this projection does not prove players will or should buy it at that point.

## Paired branch-choice dominance analysis

The eight routes form a complete 2^3 branch matrix. `analyze_branch_economic_dominance.ps1` uses that structure instead of comparing arbitrary routes.

For each branch and difficulty, every route taking choice A is paired with the one route that makes the same other two decisions but takes choice B. The report therefore isolates:

- final conservative wallet delta caused by that branch decision;
- whether the same choice has a cash advantage in every paired route;
- whether the same choice wins consistently across Cadet, Combat, Veteran and Ace;
- how much each choice changes the earliest conservative reach of sequential equipment tiers.

The report emits review signals for a paired cash difference of at least 1,000 credits or a sequential-tier timing shift of at least two sorties. It also records a `CONSISTENT_CASH_WINNER` when one choice is economically ahead on every difficulty.

These are deliberately **review prompts**, not failures. The branch screen already displays each `+CR` contract premium to the player, so differing authored premiums are transparent. The design question is whether their total route effect is proportionate to mission risk and strategic identity, which requires vulnerable human play.

## Service liability

The economy report records near-loss full-service liability for every airframe tier. Higher-capacity frames naturally create a larger absolute repair/recharge ceiling; this is evidence for human review, not justification to flatten their costs automatically.

The route stress projection deliberately retains the starting-frame service reserve so it does not silently assume an airframe purchase and then contaminate every other progression-family comparison with a different service ceiling.

## Human signoff

Release signoff schema v4 requires all of the following to belong to the same HYPERSONIC source SHA:

- vulnerable pressure summary;
- economy progression audit;
- eight-route progression projection;
- paired branch-economic dominance report;
- native Test Lab handoff.

The reviewer must explicitly set `balance.economy_evidence_reviewed`, `balance.route_projection_reviewed` and `balance.branch_economy_reviewed` after inspecting the corresponding evidence, including `never_reachable_signals`, cash-dominance signals and tier-timing differences.

## Truth boundary

Do not infer any of the following from the static, route or branch analyses alone:

- that a normal player earns the zero-score floor;
- that a normal player reaches every optional objective;
- that a weapon is fun or dominant;
- that a higher difficulty's reward multiplier correctly compensates for its pressure;
- that repeated repair bills feel fair across a complete campaign;
- that late-game purchases arrive at the right dramatic moment;
- that a player spends only within one progression family;
- that the harsh full-service reserve resembles typical damage;
- that a branch with a modest cash advantage is automatically overpowered or should have equal rewards.

Those require vulnerable completed-sortie evidence and human campaign review.

Never auto-tune rewards, branch premiums, prices, repair rates or equipment from one deterministic bot run, the conservative affordability model, a route projection or the paired branch report. Use these audits to detect regressions and identify hypotheses for human playtesting.

## Release command

The complete Windows release gate runs the economy audit, eight-route projection and paired branch-dominance analysis automatically:

```powershell
.\tools\validate_windows_release.ps1
```

Using `-SkipEconomyAudit` skips all three layers, makes the run diagnostic only and prevents issuance of the exact-SHA release receipt.
