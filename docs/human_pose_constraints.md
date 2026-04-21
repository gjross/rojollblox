# Human Pose Constraints (Coarse) – Rollblox

## Purpose

This document defines coarse human-anatomy and readability constraints for the grappling pose system.

It is not a biomechanics paper.
It is a practical guardrail document for:
- pose authoring
- sanity checking
- future refactors
- eventual IK or constraint-based posing

The goal is to prevent poses that immediately break the human read.

---

## Priority Order

When evaluating a pose, use this order:

1. **Human attachment sanity**
   - Does the head read as attached to the torso?
   - Do arms and legs read as originating from plausible shoulder/hip locations?

2. **Silhouette readability**
   - Can a viewer tell who is top and who is bottom without the HUD?
   - Can a viewer identify head, torso plane, and hips for both fighters?

3. **Position truth**
   - Does the pose read as the intended grappling position?

4. **Stylization / polish**
   - Only after 1–3 are satisfied.

If a pose fails a higher level, do not spend time polishing lower levels.

---

## Core Skeleton Contract

### Root and torso
- The torso is the primary body anchor.
- The root defines gross body placement.
- Major body parts should be posed relative to root and torso, not as independent world-space objects.

### Head
- The head must remain torso-relative.
- The head must not be independently translated in world space as if it were a loose object.
- The head should read as connected by a short neck chain to the torso.
- If the head cannot be visually associated with the torso, the pose is invalid.

### Arms
- Arms must read as originating from shoulder locations on the torso.
- Arm placement may stylize, but may not appear detached or free-floating.
- Arm positions should support the read of the position, not obscure it.

### Legs
- Legs must read as originating from hips/pelvis.
- Knee and foot direction can stylize, but should not create a detached-plank effect.
- In top/bottom positions, legs should help communicate base, control, and framing.

---

## Readability Contract

Every fighter should have these anchors readable in most gameplay views:

- **head**
- **torso plane / chest block**
- **hip center / lower-body anchor**

A pose is suspect if:
- the head disappears completely behind another torso
- the torso plane cannot be located
- the figure reads as disconnected blocks instead of a person

### Camera-read rule
If a standard gameplay camera cannot see enough of the head/torso relationship to preserve the human read, the pose should be adjusted.

The system should not rely on labels alone to explain who is where.

---

## Coarse Joint Sanity Rules

These are rough constraints, not numeric medical limits.

### Neck
- Allow only one major extreme at a time:
  - extension
  - rotation
  - lateral tilt
- Combining strong extension + strong rotation + compression is usually a red flag.
- The face should not appear to occupy a location the skull could not plausibly occupy relative to the torso.

### Spine / torso
- The torso may curl, flatten, bridge, or posture up.
- The torso should still read as one coherent trunk.
- Avoid poses where the chest and pelvis imply contradictory body directions.

### Shoulders
- Shoulders may compress and round forward under pressure.
- Arms should still appear to arise from plausible shoulder positions.

### Hips
- Hips define the lower-body center for top/bottom relation.
- If hips are visually unclear, the position read weakens quickly.

### Elbows / knees
- Avoid reverse-joint reads.
- Avoid “hinge confusion” where a limb’s bend direction reads backwards.

---

## Pose Composition Rules

### Gameplay variables
Gameplay variables may:
- perturb a baseline pose
- add pressure
- add resistance
- add motion flavor

Gameplay variables may **not**:
- define the body from scratch
- replace the base skeleton logic
- independently shove the head or limbs into unrelated world-space positions

### Baseline first
Each position should have a neutral baseline pose that is:
- anatomically readable
- visually clear
- camera-safe

Dynamic variations should be layered on top of that baseline.

### One-layer rule
When debugging:
- fix one layer at a time:
  - anatomy attachment
  - silhouette/readability
  - position truth
  - gameplay variation

Do not mix all four in one tuning pass.

---

## Position-Specific Truths

## Closed Guard

### Bottom
Closed guard bottom should generally read as:
- back on or near the mat plane
- torso visible enough to read chest direction
- head near torso line, not detached or buried
- legs wrapping or framing the top player
- a coherent bottom silhouette

### Top
Closed guard top should generally read as:
- centered between or near bottom hips
- upright or moderately forward in posture
- not collapsing backward into an implausible lean
- clearly above the bottom player in level and relation

### Closed guard failure signs
- bottom head appears detached or in the wrong lane
- top torso fully erases bottom head/torso read
- both fighters occupy the same visual lane as an unreadable block pile

---

## Mount

### Bottom
Mount bottom should generally read as:
- torso on mat / pinned orientation
- head attached and compressed plausibly
- hips and shoulders indicating defensive pressure

### Top
Mount top should generally read as:
- base above hips / torso of bottom player
- clear top dominance
- stable center of mass

### Mount failure signs
- bottom head floats forward away from torso
- top appears to sit in empty space
- bottom no longer reads as pinned beneath top

---

## Side Control

### Bottom
- shoulders and torso read as pinned / turned
- head remains attached and readable

### Top
- torso crosses and controls bottom torso lane
- hips and chest pressure read as connected

---

## Turtle / Front Headlock Family

### General truths
- spine direction matters strongly
- head and shoulders must preserve a coherent chain
- detached-block reads are especially dangerous here

---

## Violation Levels

### Green
Stylized but believable.
Readable immediately.

### Yellow
Readable, but strained.
May need cleanup if this is a common gameplay state.

### Red
Breaks the human read immediately.
Must be fixed before polishing.

Examples of likely red violations:
- head appears detached from torso
- limbs read as originating from impossible locations
- top/bottom relationship cannot be determined without HUD
- pose reads as random blocks rather than a body

---

## Debugging Checklist

Before tuning numbers, ask:

1. Is the head clearly attached to the torso?
2. Can I identify torso plane and hips?
3. Can I tell who is top and who is bottom without labels?
4. Does the pose read as the intended grappling position?
5. Are gameplay variables perturbing a baseline, or replacing it?

If the answer to 1 or 2 is no, stop and fix structure before continuing.

---

## Future IK Bridge

This document is intentionally coarse.

Later, if the project adopts IK or a constraint solver, this file should evolve into:
- joint preference ranges
- hard vs soft joint limits
- contact priorities
- camera-preservation rules
- position-specific target poses

Until then, this document is the coarse “do not break the human” contract.