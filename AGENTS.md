# Omarchy Island contributor guide

Use [`.agents/skills/omarchy-island/SKILL.md`](.agents/skills/omarchy-island/SKILL.md) for any host, provider, or plugin-integration change.

Keep these boundaries intact:

- Island is one movable widget inside the stock Omarchy bar. Do not replace, hide, re-parent, or duplicate the stock bar or its widgets.
- Treat `/usr/share/omarchy` as read-only reference material. Extend Omarchy through plugin manifests, provider entry points, and public shell behavior.
- A normal `bar-widget` does not automatically belong in Island. Island shows first-party adapters, explicit `omarchyIsland.quickAccess`, and published provider activities.
- Prefer declarative activity data. Add custom presentation QML only when the fallback view cannot preserve the intended interaction.
- Let the host own outer geometry, borders, animation, focus, dismissal, keyboard navigation, and monitor routing.
- Preserve stock commands and panels for established Omarchy actions. Never run a system update or start/stop a real recording from an automated check.
- Keep the OSD replacement optional. The main Island install must leave `omarchy.osd` enabled; only the explicit `rblalock.omarchy-island-osd` companion may replace it, and disabling that companion must restore the stock presenter. Preserve its fallback so system feedback is never silently lost.
- Now Playing, Reminders, Screen Recording, and System Update are bundled providers. A normal `omarchy plugin add ... --enable` must activate them without helper scripts or extra plugin installs.

Run `./scripts/check` after implementation. For a live host check, use
`./scripts/dev-sync`, then inspect with `omarchy-shell omarchy-island inspect`.
Installation is not permission to trigger a provider's destructive or
externally visible action.
