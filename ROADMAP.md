# Roadmap

Omarchy Island 0.1 focuses on a dependable bar widget, explicit first-party
adapters, and a small versioned provider contract. Future work should preserve
that boundary rather than turning Island into another bar or panel framework.

## Next

- Exercise monitor hotplug and focused-monitor handoff across more hardware.
- Decide how a long tray inventory should collapse or overflow.
- Explore notification activity without replacing Omarchy's notification UI.
- Add deeper network or power adapters only where stock state and actions are
  available through a stable, feature-detectable boundary.
- Add alternate scale and style profiles after the default remains legible
  across common Omarchy themes.

## Compatibility policy

- Schema version 1 remains additive: existing required fields and action
  semantics do not change within the version.
- New capabilities require a schema update or an explicitly optional extension.
- Bundled providers are reference implementations, not private APIs.
- A failing external replacement must never prevent its bundled fallback from
  returning during the same registry reconciliation.
