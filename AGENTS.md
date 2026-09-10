# Omarchy Island contributor guide

Use [`.agents/skills/omarchy-island/SKILL.md`](.agents/skills/omarchy-island/SKILL.md) for any host, provider, or plugin-integration change.

Keep these boundaries intact:

- Island is one movable widget inside the stock Omarchy bar. Do not replace, hide, re-parent, or duplicate the bar.
- Treat `/usr/share/omarchy` as read-only reference material. Extend Omarchy through plugin manifests, provider entry points, and public shell behavior.
- A normal `bar-widget` does not automatically belong in Island. Island shows first-party adapters, explicit `omarchyIsland.quickAccess`, and published provider activities.
- Do not instantiate arbitrary bar widgets for discovery. The clock, indicators,
  and keyboard-layout adapters have narrow hidden compatibility bridges because
  their current Omarchy behavior has no independent service API. Keep that list
  explicit and do not generalize it.
- Prefer declarative activity data. Add custom presentation QML only when the fallback view cannot preserve the intended interaction.
- Let the host own outer geometry, borders, animation, focus, dismissal, keyboard navigation, and monitor routing.
- Preserve stock commands and panels for established Omarchy actions. Never run a system update or start/stop a real recording from an automated check.
- Keep the OSD replacement optional. The main Island install must leave `omarchy.osd` enabled; only the explicit `rblalock.omarchy-island-osd` companion may replace it, and disabling that companion must restore the stock presenter. Preserve its fallback so system feedback is never silently lost.
- Now Playing, Reminders, Screen Recording, and System Update are bundled providers. A normal `omarchy plugin add ... --enable` must activate them without helper scripts or extra plugin installs.

Run `./scripts/check` after implementation. For a live host check, use
`./scripts/dev-sync`, then inspect with `omarchy-shell omarchy-island inspect`.
Installation is not permission to trigger a provider's destructive or
externally visible action.

## Code map

- `IslandBarWidget.qml` owns Rest, horizontal-bar Peek/transients, the vertical
  Rest anchor, and bar gestures.
- `RetainedWindow.qml` owns focused-monitor Detail, keyboard capture, and the
  horizontal Peek/transient surface that grows inward from a vertical bar.
- `components/CompactSurface.qml` is the single shared Peek/transient renderer;
  do not duplicate its controls in either host.
- `Service.qml` coordinates configuration, stock adapters, semantic activity,
  provider ownership, and IPC.
- `lib/ProviderContract.js` is the schema-version and capability validator.
- `docs/plugin-api.md` is the canonical provider contract; the skill reference
  is an implementation checklist, not a second schema.
- `providers/system-update/` is the smallest provider example.
- `tests/runtime/provider-conformance.qml` is the contract and lifecycle gate.
