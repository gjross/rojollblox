# AGENTS.md

## Repo basics
- (your existing notes: rojo, structure, etc.)

---

## Coding principles
- keep functions readable over clever
- avoid hidden coupling
- prefer explicit transforms

---

## Pose system rules

Follow:
- /docs/human_pose_constraints.md
- /docs/pose_system_contract.md
- /docs/pose_library_contract.md
- /docs/pose_family_inventory.md

Non-negotiable:
- torso is the main anchor
- head must remain torso-relative
- no independent world-space head placement
- no mixed reference frames in a single pose
- gameplay variables are modifiers only

When editing poses:
1. baseline pose first
2. ensure readability (top/bottom, head, torso)
3. then apply light modifiers
4. do not compensate for broken poses with offsets

Definition of done:
- pose reads correctly without HUD
- both fighters are anatomically coherent
- code follows pose_system_contract.md