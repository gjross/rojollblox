# Pose Family Inventory – Rollblox

## Purpose

This file defines the initial “realm map” of grappling positions.

It is intentionally:
- short
- coarse
- practical

It answers:
> what must the player instantly understand when they see the scene?

This is NOT about perfect realism.
This is about **readability and coverage of the game space**.

---

## Families (Initial Scope)

We start with 4 families:

1. Standing
2. Closed Guard
3. Mount
4. Side Control

Each family defines:
- what must be visually obvious
- baseline pose intent
- initial variants (future)

---

# 1. Standing

## What must be obvious
- two fighters upright
- facing each other
- space between them
- potential for engagement

## Baseline pose intent
- neutral stance
- balanced posture
- hands available (not locked in extreme positions)
- readable head + torso for both

## Future variants
- cautious distance
- forward pressure
- initial grip / collar tie
- disengage/reset

---

# 2. Closed Guard

## What must be obvious
- one fighter on bottom (on back)
- one fighter on top between legs
- legs of bottom wrapping / controlling top
- clear vertical relationship (top vs bottom)

## Baseline pose intent

### Bottom
- torso on or near mat plane
- head attached and readable
- legs wrapped around top
- hips centered under top

### Top
- positioned between bottom’s hips
- torso upright or slightly forward
- hands near torso/head lane of bottom
- clearly above bottom

## Future variants
- top postured up
- top posture broken forward
- bottom attack-ready (triangle / arm control feel)
- bottom defensive (frame / control)
- hip-bump setup

---

# 3. Mount

## What must be obvious
- one fighter sitting on top of another’s torso/hips
- bottom pinned on back
- top clearly dominant

## Baseline pose intent

### Bottom
- torso flat or slightly turned
- head attached and visible
- arms in defensive framing or neutral position
- hips under top

### Top
- knees or base outside bottom hips
- torso above bottom chest
- stable center of mass
- posture slightly forward or neutral

## Future variants
- high mount posture
- low chest pressure
- bottom bridge attempt
- bottom framing/escape setup
- top adjusting balance

---

# 4. Side Control

## What must be obvious
- bottom on side or slightly turned
- top perpendicular across torso
- chest-to-chest control feeling

## Baseline pose intent

### Bottom
- torso rotated (side orientation)
- head attached and readable
- arms framing or neutral
- hips partially turned

### Top
- torso crossing bottom torso lane
- hips and chest applying pressure
- stable base (legs supporting weight)
- clear perpendicular relationship

## Future variants
- heavy chest pressure
- transition-ready (knee slide / mount attempt)
- bottom framing strongly
- bottom turning in (toward guard recovery)

---

## Cross-Family Rules

These apply to ALL families:

- top vs bottom must be readable without HUD
- both heads must be locatable
- torso planes must be identifiable
- silhouettes must not collapse into one block
- poses must follow:
  - human_pose_constraints.md
  - pose_system_contract.md

---

## Baseline First Policy

For now:

- implement ONLY baseline pose pairs for each family
- no heavy gameplay modifiers
- no extreme expressions
- no advanced transitions

Goal:
> get 4 families that “look right” at a glance

---

## Definition of Done (Phase 1)

This file is successful when:

- each family has a baseline pose pair implemented
- switching between families produces clearly different readable scenes
- a viewer can identify the position without UI labels
- no pose feels like “random overlapping blocks”

---

## Next Phase (after this works)

Once baseline families read correctly:

- add 2–3 variants per family
- introduce light gameplay modifiers
- begin smoothing transitions between variants