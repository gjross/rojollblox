## Pose sanity rules

Follow `docs/human_pose_constraints.md`.

Non-negotiable rules:
- torso is the main body anchor
- head must remain torso-relative
- do not translate heads independently in world space
- gameplay variables may perturb a baseline pose, not define the body from scratch
- top/bottom relationship must read without relying on HUD labels
- if head/torso/hips are not readable, the pose is not done

When editing poses:
1. fix attachment sanity
2. fix silhouette/readability
3. fix position truth
4. only then add dynamic variation

Prefer clean baseline pose functions over layered offset hacks.