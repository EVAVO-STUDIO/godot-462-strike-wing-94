# HYPERSONIC production design

Preserve the existing VX-94 campaign and Mercenary War → Machine War → BLACK SKY canon: 30 campaign sorties, six secrets, 38 enemy identities, nine bosses, variable craft, equipment economy, support, saves, accessibility and challenge modes. This is the design for the next integration pass, not a claim that the new mechanics already exist. Media sources and native art reviews remain under `assets/source`; audio listening and final integrated verification remain release work.

## Flight and camera

Integrate actual speed into unbounded forward aircraft position. The camera follows smoothly with speed-dependent lookahead. Visible aircraft position is a projection relative to that camera, never a rectangular forward-travel clamp. Lateral movement stays within the authored combat corridor. Longitudinal movement input affects the speed command instead of independently sliding the aircraft into a screen wall. Preserve configurable actions, controller bindings, explicit throttle, afterburner and altitude controls.

Retain 0.62 / 1.00 / 1.36 / 1.78 / 4.40 as the initial minimum/cruise/military/afterburner/hypersonic tuning envelope. Power commands change actual speed continuously; the fighter cannot stop or hover. Tune acceleration, deceleration and lookahead against captures, including maximum-speed recognition distance. Pause/resume, transforms and altitude changes must not jump position.

Terrain, surface targets, pickups, airborne contacts, projectiles and precipitation share consistent relative motion. Apply camera displacement exactly once; do not double-count existing closure multipliers. Cloud depth and wind remain independent. Keep travelled distance as the spatial campaign clock and elapsed time for cooldowns and genuinely timed objectives.

## Updated player direction: attack runs and propulsion

Speed is a tactical commitment: increasing it shortens time over a surface target; reducing it permits a longer firing/bombing solution at greater exposure. Preserve momentum and finite control authority. Do not restore arcade vertical sliding or disguise a fixed-speed route with speed lines. Required command contacts need an authored interception/loiter solution; optional targets may be passed. Audit stationary boss holding separately from terrain-fixed targets when applying route closure.

Give conventional primary mounts three recognisable choices within the existing loadout economy: a compact single fighter autocannon, paired autocannons with higher sustained demand and spread/weight tradeoffs, and a heavy bomber nose autocannon with harder-hitting projectiles and attack-run commitment. Real aircraft are visual/role inspiration, not claims of exact F-16/A-10 simulation. Bombs, rockets and guided missiles retain distinct release, aiming and guidance behaviour; do not collapse them into interchangeable damage upgrades. Preserve existing weapon ownership IDs through any mapping/migration.

Hypersonic entry needs an authored, short propulsion event: engines flare bright blue, a shockwave burst originates at the engines, and rapid actual acceleration follows. Sustain readable blue exhaust at speed, with recovery on release. This is the VX-94's fictional high-speed technology. Integrate the art, sound event and actual speed threshold once per entry; do not replay the burst every frame or substitute a full-screen flash. Reduced-flashes mode retains a restrained readable cue.

Countermeasure flares are essential with lethal guided weapons. Preserve the existing equipment and cooldowns. Heat-seeking threats should visibly divert on successful seeker break; timing and spatial separation matter. Distinguish other guidance classes and avoid universal invulnerability. Test intercepted/decoyed missiles separately from direct impacts and keep the visible flare, seeker path, warning and telemetry outcomes consistent.

## Route rhythm

The source-bound audit in `work/campaign_design_v3/audit.json` covers all 36 sorties in canonical order. Every current normal boss gate is reached after elapsed-time expiry at minimum power: the gate is 0.72 of nominal route length while minimum speed is 0.62. Fourteen sorties also have authored beats beyond the default boss gate. These conflicts require correction with the flight model.

Ordinary sorties complete through objectives and their command encounter, without failure solely for flying slowly. Keep nominal duration as route-length metadata. Explicit countdowns must identify a concrete threat in briefing/HUD/radio; do not add silent generic deadlines. Retain bounded boss overtime once the command encounter actually begins.

Preserve late authored beats. Place command arrival after the final required escort/approach beat and a readable separation, or explicitly treat that beat as part of the command encounter. Optional secrets do not delay normal completion. At high speed, preserve spatial order without emitting several overdue formations in one frame. Give newly presented threats a minimum real-time recognition gap. Suppress filler during recovery and command-arrival windows. Required targets remain reachable; missing an optional opportunity never fails the sortie.

## Damage and fairness

Classify direct warheads, cannon fire, fragments, energy attacks and collisions explicitly. Direct guided-missile or rocket impact is normally catastrophic even on an upgraded craft. Active interception/countermeasures prevent impact; passive shields cannot make a successful warhead hit routine chip damage. Avoid arbitrary survival dice rolls.

Initial tuning target: two to three solid cannon hits threaten the basic craft; structural upgrades buy limited additional tolerance. Cannon penetrates a substantial portion of passive shielding. Fragments, grazing fire and near misses can leave recoverable damage. Fields remain useful against fragments and energy. Preserve airframe/shield capacities, ownership and save identities while changing damage interaction. Pickups and tankers cannot resurrect a destroyed craft.

Ship lethality with readable launch-to-impact time at maximum approach speed, an escape direction and reliable seeker-break feedback. No fatal missile from an unseen point-blank launcher. Cadet offers longer warning and lighter pressure; Veteran/Ace increase coordination while preserving a minimum recognition window. Validate normal-vulnerability encounters rather than extrapolating from invulnerable telemetry.

## Roles and economy

Retain LOW bomber's stable attack runs, rotary nose mount, visible stores and AAA/SAM exposure; HIGH fighter's interception, tighter profile and afterburner efficiency; MID's mixed/tanker role; and authored ORBITAL restrictions. Keep the principles in `ALTITUDE_ROUTE_DESIGN.md`. Brief a required form/altitude change before the decision point, allowing transformation and mount-deployment time. Optional lane bonuses must not become hidden completion prerequisites.

Preserve conventional → electromagnetic → directed-energy → strategic escalation. Cannon handling, rail penetration, Storm energy demand and Plasma commitment remain distinct. Generator, support and afterburner budgets compete visibly. The free baseline loadout stays viable. Fire only from a visible ready mount; external releases remove missiles/bombs while spent rocket pods retain their housings.

Spectre suppresses surface threats; Rapier covers air pressure; Hammer performs surface strikes; Atlas offers deliberate recovery; rail/cruise/orbital support resolves marked threats. Explain unavailable altitude and reject invalid requests without consuming readiness. No new resource system is needed.

Higher lethality must not create a repair-cost spiral. Preserve equipment ownership and allow a baseline retry at zero credits. Reward clean flight and mastery without requiring farming after ordinary failure. Tune repair/rearm cost against earnings from completed vulnerable sorties. The current eight 36-second invulnerable runs do not establish economy or boss balance.

## Branch consequences

Preserve three branch IDs, choices, credit differences and reconvergence points. Add one bounded, visible consequence through existing saved decisions and contacts/support; do not create a faction meter. Old saves lacking a choice receive the ordinary encounter. Apply consequences once and acknowledge them in the branch UI and reconvergence briefing/radio. Unchosen missions remain available for replay.

| Branch | First choice | Second choice |
| --- | --- | --- |
| Breakwater Crisis | Furnace Line weakens one armored escort on Desert Lance. | Black Flag provides a Rapier cover opportunity on Desert Lance. |
| Machine Contact | Dead Factory weakens a ground escort in Ghost Convoy. | Iron Rain weakens an airborne escort in Ghost Convoy. |
| Orbitfall Vector | Kinetic Dawn provides one existing rail-support opportunity at Cold Station. | Orbitfall provides one existing Atlas recovery opportunity at Cold Station. |

## Secrets and modes

Keep all six sortie unlock IDs and parent encounters. Intelligence/radio previews the kind of opportunity; discovery or a near miss reveals the exact condition. Accuracy, score, route/form and priority-target mastery remain distinct. Use readable opportunity windows rather than unannounced one-frame gates. Missing a secret must not block campaign completion; make retries clear.

Every secret director must consume the actual active secret mission. Correct the known ordinary-catalogue fallbacks in environment, encounters and radio. Seed Manifest needs its evacuation-grid/city setting; secrets must not inherit Coastal Intercept's Gunship Probe. Mission-specific direction is in `CAMPAIGN_SORTIE_REVIEW.md`.

Preserve Arcade Assault's twelve-sortie compression and lives, Hypersonic Trial's high/orbital pursuit and Strike Mastery's low bomber role. Adapt their route clocks to actual travel. Boss Rush currently advertises seven targets but covers only five unique bosses. Refine it to nine existing identities once each: Gunship Alpha, Armoured Train, Missile Cruiser, Swarm Controller, AI Forge Core, Orbital Command Node, Phase Control Array, Station Warden and Machine Ark. Preserve its post-campaign unlock and migrate existing mode records.

## Integration and proof

Implement necessary flight/camera/route timing and damage classification together, then integrate retained pose/mount art, cloud selection, precipitation/audio, secret selectors, cinematic sound bridges and destruction continuity. Keep existing systems; do not replace the game with a new framework.

Run `validate.ps1`, Windows release gate, native stress, expanded visual matrix and the existing eight-sortie telemetry process. Supplement them with minimum-throttle completion, maximum-speed warnings, nine natural boss encounters, direct missile lethality versus recoverable fragments, zero-credit retry, three branch consequences and six real secret sorties. Record speed, player/camera travel, damage class, countermeasure result, objective timing, accepted support and recovery cost.

Inspect normal-vulnerability native gameplay at real elapsed time. Numeric audio review supplements listening; addressed fixtures supplement natural playback. Preserve all useful work, finish cleanly on main, commit and push only after the complete release audit.
