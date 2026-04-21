# Pose System Contract – Rollblox

## Purpose

This document defines how pose code must be structured.

It prevents:
- drifting offsets
- detached parts
- inconsistent pose logic
- gameplay variables corrupting anatomy

This is not about realism.
This is about **system stability and predictability**.

---

## Core Principle

> Every pose must be built from a **single coherent reference frame**.

If different body parts use different frames of reference, the pose will break.

---

## Coordinate Hierarchy

All pose functions must follow this order:

1. `root` (world placement)
2. `torsoCf` (primary body frame)
3. all other parts relative to torso or root

### Required pattern

```lua
local root = CFrame.new(rootPos) * ...

local torsoCf = root * ...

local headCf = torsoCf * ...
local armCf = torsoCf * ...
local legCf = root * ...