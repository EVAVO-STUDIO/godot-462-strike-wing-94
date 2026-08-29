# Strike Wing '94 Strategic-Orbital Endgame

## Purpose

The strategic-orbital era is the end of the current 12-mission machine-war campaign. It must feel like a culmination of the same 1999 imagined-future military technology, not a genre switch into generic space fantasy.

The first true strategic-orbital mission is **M12: Machine Ark**. External/alien contact remains outside the current playable campaign.

## Mission 12 structure

Machine Ark begins in the **HIGH** altitude band rather than spawning directly in space.

The opening phase gives the player one final upper-atmosphere preparation window with:

- Rapier Fighter Flight;
- Atlas Tanker;
- Longshot Rail support;
- Orbital Strike support.

The authored **FINAL REARM WINDOW** occurs around 137 seconds. The player can spend scarce tactical ordnance, hold formation with Atlas, restore the finite afterburner reserve and rearm tactical/strike systems while the tanker is still legal at high altitude.

At roughly **156 seconds** the authored **FINAL ORBITAL BURN** moves the VX-94 into the orbital band. The environment must show high cloud / atmospheric curvature before this transition and full orbital presentation afterward.

This creates a deliberate sequence: fight through the upper-atmosphere screen, decide whether to risk the tanker hookup, then enter the final orbital phase with whatever resources the player successfully preserved or restored.

## Plasma Lance

The Plasma Lance is the eighth primary tier and the first primary restricted to the `strategic_orbital` technology era.

Role:

- one heavy packet;
- high direct damage;
- slow cadence;
- very high generator demand;
- large but bounded field discharge;
- no penetration identity overlap with Needle Rail;
- no multi-pulse identity overlap with Storm Cannon.

Current authored identity:

- one projectile;
- direct damage 8;
- 0.34 s fire interval;
- projectile speed 390;
- energy cost 28;
- 26,500 credits.

The field discharge may affect at most three nearby secondary targets and secondary damage must always remain nonlethal. Direct projectile collision remains the kill/score/objective owner.

## Micro-Warhead Rack

The Micro-Warhead Rack is the strategic-orbital tactical-support endpoint.

It is not a reusable screen-clearing nuclear button.

Current identity:

- one guided penetrator;
- direct damage 20;
- energy cost 42;
- 999 s cooldown;
- one projectile per activation;
- strategic-orbital purchase gate;
- 31,800 credits.

A fresh sortie resets tactical cooldown. Without support, the Micro-Warhead is effectively one use during a normal mission. A successful Atlas tanker hookup resets the tactical cooldown and can therefore rearm the strategic shot before the orbital phase.

The projectile may create one bounded pre-impact burst:

- 18 px trigger envelope;
- 58 px blast radius;
- at most four secondary targets;
- four secondary damage;
- secondary damage is nonlethal.

The direct guided projectile remains responsible for any actual kill.

## Afterburner / tanker refuel

The VX-94 now has a finite afterburner reserve rather than unlimited speed boost.

Current flight identity:

- 8 seconds total reserve per fresh sortie;
- `Shift` activates afterburner;
- fighter configuration receives the stronger boost;
- bomber configuration keeps a smaller emergency boost;
- fuel drains only while the boost is actually held;
- no passive fuel-management burden.

A successful Atlas rearm calls the craft's public refuel API and restores afterburner reserve to full. This gives the tanker a genuine refuelling role without converting the game into a fuel simulator.

## Late airframes

The late VX-94 frames remain physically recognisable upgrades to the same airframe.

### Magneto-Composite

- electromagnetic era;
- 155 hull / 135 shield capacity;
- 0.86 incoming-damage multiplier;
- visible restrained magnetic field nodes.

### Field-Coupled

- directed-energy era;
- 165 hull / 160 shield capacity;
- 0.80 incoming-damage multiplier;
- visible field-lattice marks.

Damage resistance is applied through canonical `CombatRules` and never creates a hidden extra health layer. Minimum incoming damage remains one.

## Visual language

Strategic technology should look like a late-1990s military artist imagining advanced aerospace weapons:

- physical emitters, rails, field nodes and reinforced housings;
- visible power-management hardware;
- segmented plasma/energy packets rather than smooth modern bloom;
- warning rings, targeting brackets and hard pixel geometry;
- restrained cyan/violet/white energy palette;
- no magical glowing armor shell;
- no superhero or clean smartphone-era sci-fi styling.

### Projectile separation

- conventional: warm ballistic streaks;
- Needle Rail: thin cyan-white kinetic dart with long wake;
- Storm Cannon: compact blue pulse packets;
- Plasma Lance: thick violet/cyan lance with segmented wake;
- Micro-Warhead: heavy guided body with warning ring and long amber/red wake.

## Boss escalation

The final autonomous bosses must not feel like larger versions of early drones.

- Phase Control Array: concentric field-array machine and crosslock salvos;
- Station Warden: fortified orbital station and energy-grid salvos;
- Machine Ark: broad asymmetric mobile command/factory carrier and strategic kinetic lanes.

Boss-support, bomb, Plasma secondary discharge and Micro-Warhead secondary blast remain nonlethal. The player must finish the boss through direct combat.

## Readability rule

Strategic-orbital technology may be spectacular, but the game remains a 640x360 pixel shooter.

Never allow:

- giant opaque effects covering enemy bullets;
- full-screen bloom;
- excessive additive particles;
- unbounded blast chains;
- support effects that erase bosses;
- effects whose gameplay boundary is visually unclear.

Every strategic effect needs a readable silhouette, bounded target count/radius, and clear relationship to the same combat rules used earlier in the campaign.
