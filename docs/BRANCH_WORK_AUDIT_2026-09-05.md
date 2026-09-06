# Branch and worktree audit — 2026-09-05

The authoritative checkout is `main` at `34379f3e6654ca480b824b62c0deba3d966337c4`, matching `origin/main`. No local or remote topic branches exist.

One retained detached review worktree exists at `work/vx94_transform_v2/runtime_review`, pinned to `3c77897ae67c3444b7ccce2211effc95d0d27fd1`. That commit is an ancestor of current `main`; `main..3c77897` contains no commits.

The detached worktree was audited without reset or deletion:

- Every non-import untracked file also exists byte-identically in the authoritative main worktree; unique file count is zero.
- All modified production PNGs inspected by hash are byte-identical to the corresponding main-worktree versions.
- Its only two differing non-import tracked files are `scripts/environment_director.gd` and `tools/environment_self_test.gd`. The current main versions supersede them with production weather rendering, camera route distance, high-altitude extinction, vertical hypersonic streaks, continuous cloud traversal, altitude-family crossfades, and the associated coverage.
- The remaining modified files are Godot `.import` metadata generated during isolated native review.

No cherry-pick, merge, checkout, reset, cleanup, or worktree removal is required. The retained detached worktree remains available as historical runtime-review evidence while production work continues on `main`.
