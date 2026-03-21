---
name: skills_bom
description: bom skill exists for maintaining flat/structured BOM files on this project
type: project
---

A `/bom` skill is installed at the skills-plugin path. It maintains three files:
- docs/bom-flat.md — single-level, aggregate quantities, procurement-focused
- docs/bom-structured.md — L0/L1/L2 hierarchy, per-parent quantities, engineering-focused
- docs/bom-order.csv — ordering sheet matching flat BOM item numbers

**How to apply:** When the user asks to add/remove/change parts or says "/bom", use the bom skill. It reads existing files first, understands the change, and updates all three files consistently in one pass.
