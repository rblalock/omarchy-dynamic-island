---
name: omarchy-island
description: Build, modify, review, or validate Omarchy Island hosts and integrations. Use for Island activity providers, quick access registration, custom presentations, host adapters, manifest changes, provider tests, or questions about making an Omarchy shell plugin work with Island.
---

# Omarchy Island

Extend the existing Island contract without creating another bar, panel system, or private plugin registry.

## Start with the smallest integration

1. Inspect the target plugin manifest and its installed Omarchy behavior. Treat `/usr/share/omarchy` as read-only.
2. Choose one integration shape:
   - Use `omarchyIsland.quickAccess` for a stateless shortcut to an existing panel or application.
   - Use an activity provider for ongoing or event-like state.
   - Add a first-party host adapter only for stock behavior that cannot register itself.
3. For an activity, publish semantic fields first. Use the host fallback before adding custom QML.
4. Add only the presentation levels whose behavior materially needs custom layout.
5. Reuse the stock command or panel for established Omarchy actions.

Read [references/provider-api.md](references/provider-api.md) before authoring or changing a provider.

## Preserve host ownership

- Keep Island as one movable widget in the normal Omarchy bar.
- Do not hide, replace, or mirror the stock bar. Do not instantiate arbitrary
  bar widgets for discovery; only the repository's documented clock,
  indicators, and keyboard-layout compatibility bridges are allowed.
- Do not infer Island membership from `bar-widget` registration.
- Do not let provider QML own the outer surface, border, window, hover target, dismissal, monitor selection, or keyboard loop.
- Use `primaryAction` only for an established single-activation behavior. Otherwise let activation open Activity Focus.
- Make `start()` and `stop()` idempotent. `stop()` must stop timers/processes and withdraw provider state.
- Bound external commands and handle unavailable dependencies without leaving stale activity.

## Choose a canonical example

- The providers under `providers/` are bundled with the host but remain the
  canonical contract examples. Copy `providers/system-update/` for the minimal
  declarative provider shape and add a third-party manifest from
  `references/provider-api.md`.
- Consult `providers/screen-recording/` for a primary action, compact mark, and completion event without a custom expanded view.
- Consult `providers/reminders/` for deadlines, multiple records, and an expanded action surface.
- Consult `providers/now-playing/` only when real custom compact and expanded presentation is warranted.

Do not copy every entry point from the richest provider by default.

## Validate safely

Run:

```bash
./scripts/check
```

When live validation is appropriate, sync the complete host and then read back:

```bash
./scripts/dev-sync
omarchy-shell omarchy-island inspect
```

Read `.providerDiagnostics` to confirm the source plugin, provider lifecycle
status, errors, and active activity keys. Then confirm normalized activity
data, withdrawal, and focused-monitor routing when those behaviors are in
scope. Do not trigger a system update, start or stop a real recording, or
invoke another destructive/external action during automated validation. Do not
commit or push unless the user asks.
