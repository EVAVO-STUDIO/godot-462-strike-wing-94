# Campaign weather art direction

`placement.json` assigns a presentation profile to every existing campaign mission and secret sortie. This is delivery metadata for the completed rain/snow studies, not active game configuration or a change to campaign canon. Catalogue hashes bind the assignments to the reviewed missions. Clear sorties retain the established environmental artwork; precipitation is not applied everywhere.

Rain remains short, slate-grey and non-emissive. Snow belongs to the mountain storm wall. The high lane is above the precipitation deck: blend precipitation out during the existing altitude transition, while keeping cloud immersion a separate visual layer. Orbital environments exclude precipitation even if a craft reports a lower lane. Earth cloud cover can remain visible far below. Descent reverses the opacity blend without restarting particle positions.

Particle motion combines travelled distance at each depth with independent wind and elapsed time. Acceleration must not reset weather phase or simply accelerate a screen overlay. Existing rain/snow native studies demonstrate relative travel, but do not implement the requested forward-flight camera or new damage model.

Keep lock warnings, missiles and radio/UI readable. Avoid full-screen lightning. Reduced-effects settings should reduce weather density and opacity consistently. Rain/wind audio still needs a mixed audition beneath radio, engines and missile warnings. Heavy cloud occlusion must not create unavoidable threats when the later flight/lethality design is integrated.

Before production integration: review altitude crossings, drizzle/rain/storm/snow in motion, orbital exclusion, reduced effects and all secret environment selectors. The current cloud selector also needs to distribute the four shapes per altitude family independently of simultaneous cloud count, without swapping a visible cloud texture mid-flight.
