# Pose Library Contract – Rollblox

## Purpose

This document defines the shape of the pose library for Rollblox.

It is not a detailed animation system spec.
It is a practical contract for building a grappling pose system that is:

- readable
- stylized but believable
- easy to author
- easy to debug
- compatible with future IK / constraints / blending

This document sits above individual pose math.
It defines the **realm** of the system, not one narrow case.

---

## Why this exists

The project should not rely on ad hoc transform math to "discover" grappling realism.

Instead, the system should be organized around:

- authored pose families
- contact relationships
- readability rules
- controlled modifiers

The pose library is the bridge between:
- gameplay state
- human-readable grappling scenes
- future technical systems

---

## Core Principle

> Grappling should be built from authored relational poses, not from isolated body-part offsets.

A pose is not just:
- where one torso is
- where one head is

A pose is:
- how both fighters relate
- where contact lanes are
- what the viewer should understand at a glance

---

## System Layers

The pose system should be thought of in layers:

### Layer 1 — Pose Library
Authored baseline poses for each position and role.

### Layer 2 — Contact / Relationship Rules
Rules about how the two fighters align and interact.

### Layer 3 — Modifiers
Small adjustments driven by gameplay state.

### Layer 4 — Camera / Presentation
Rules that preserve readability.

### Layer 5 — Future Systems
Optional later additions:
- IK
- constraints
- blending
- animation transitions

If Layer 1 is weak, the rest will not save it.

---

## Definitions

### Pose
A pose is a structured snapshot of body-part transforms for one fighter relative to a local reference frame.

### Pose Pair
A pose pair is the authored relationship between:
- top fighter pose
- bottom fighter pose

Most grappling states should be authored and reasoned about as pose pairs, not isolated single-fighter poses.

### Pose Family
A pose family is a group of related pose pairs for one position.

Example:
- `ClosedGuard`
- `Mount`
- `SideControl`
- `Turtle`
- `BackControl`
- `StandingTie`

### Baseline Pose
The simplest, most readable pose in a family.
No major reactions. No dramatic gameplay distortion.

### Variant Pose
A pose derived from a baseline family concept but expressing:
- pressure
- posture break
- escape start
- attack start
- defensive reaction

### Modifier
A small transformation layered on top of a baseline or variant pose.
Modifiers should never replace the base pose logic.

---

## What the library is responsible for

The pose library is responsible for:

- defining believable baseline body organization
- preserving top/bottom readability
- making grappling positions recognizable
- giving the camera something readable to show
- creating a stable base for gameplay modulation

The pose library is NOT responsible for:
- inventing contact realism from scratch
- solving all collisions
- compensating for a bad camera
- replacing a constraint solver

---

## Authoring Philosophy

### 1. Author positions as relationships
Do not think:
- "where should this head be?"

Think:
- "what is the relationship between these two bodies in this position?"

### 2. Prefer families over one-off hacks
Every common position should have a family of authored baselines and variants.

### 3. Baselines first
Every family must have at least one baseline pose pair that reads clearly with all gameplay modifiers disabled.

### 4. Modifiers are small
Pressure, resistance, and aggression should perturb an existing pose, not generate one from nothing.

### 5. Readability beats realism
If a perfectly "real" angle destroys the read, prefer the readable stylized pose.

---

## Pose Library Realm

The library should cover the **realm** of the game, not a single narrow demo.

At minimum, the system should be organized by these families:

### Standing / Engagement
- neutral stand
- cautious stand
- collar tie / grip engagement
- distance management

### Guard Families
- closed guard
- open guard
- half guard
- butterfly-style seated guard (future)

### Dominant Top Families
- mount
- side control
- knee-on-belly (future)
- north-south (future)

### Transitional Families
- posture break
- guard opening attempt
- mount escape start
- hip bump / bridge start
- shrimp / frame start

### Turtle / Back Exposure Families
- turtle baseline
- front headlock style top
- back-take entry staging

This does not mean all need full implementation immediately.
It means the library should be designed so these families fit naturally.

---

## Required Pose Pair Structure

Each authored pose pair should define:

- top fighter root frame
- bottom fighter root frame
- top torso transform
- bottom torso transform
- top head transform
- bottom head transform
- top arms
- bottom arms
- top legs
- bottom legs
- optional notes about contact lanes and camera assumptions

A pose pair is complete only when both fighters together read correctly.

---

## Contact and Relationship Lanes

The pose library should think in lanes, not just coordinates.

Important lanes include:

### Head lane
Where each head is expected to be readable.

### Torso lane
Where each chest/torso mass is expected to read.

### Hip lane
Where base and center-of-mass relationship is communicated.

### Limb lane
Where arms and legs support control, framing, or base.

If two key lanes collapse into unreadable overlap, the pose pair is suspect.

---

## Required Readability Outcomes

For a pose pair to be acceptable, a viewer should be able to tell:

- who is top and who is bottom
- what the rough grappling position is
- where each head is
- where each torso is
- what the likely control relationship is

This should be true even before HUD labels are read.

---

## Suggested Data Model

The system should move toward authored pose data rather than deeply embedded pose math.

Example shape:

```lua
PoseLibrary = {
  ClosedGuard = {
    Baseline = {
      Top = { ... },
      Bottom = { ... },
      ContactRules = { ... },
      CameraHints = { ... },
    },
    TopPostured = {
      Top = { ... },
      Bottom = { ... },
      ContactRules = { ... },
      CameraHints = { ... },
    },
    BottomTriangleThreat = {
      Top = { ... },
      Bottom = { ... },
      ContactRules = { ... },
      CameraHints = { ... },
    },
  },
}