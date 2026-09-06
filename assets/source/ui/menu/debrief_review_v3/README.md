# Debrief presentation review

Current-main success and failure fixtures were captured with pinned Godot 4.6.2 and visually inspected. Success clearly displays MISSION COMPLETE, rating and next-mission/retry actions. Failure displays SORTIE FAILED, airframe recovery and retry-only actions. The existing art/layout was retained.

The success fixture previously displayed zero completed objectives despite claiming mission completion. Its capture-only initialization now resets objective progress and fills recognized objective targets for success. The final native capture shows OBJECTIVES 4/4. Failure remains incomplete. This changes deterministic screenshot setup only, not campaign objective evaluation or rewards.

The standard tools/run_visual_qa.ps1 matrix now includes debrief_failure with the recognized --capture-result=failure value. An initial manual attempt used unsupported 'failed' and produced gameplay; that image was rejected as debrief evidence. The verified failure capture uses the supported flag.

Mission-flow test passes with the existing ObjectDB exit warning. One intermediate run failed a source-string assertion after a Windows write changed main.gd line endings; restoring its LF endings resolved it without changing spawn-profile behaviour. The full Windows release gate has not been rerun for this review.

These synthetic fixtures verify presentation only. Real completion, failure, rewards and repair accounting still require the final gameplay telemetry/release review.
