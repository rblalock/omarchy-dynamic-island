# Changelog

## 0.2.1 - 2026-09-11

- Restore optional OSD routing on Omarchy 4.0.3 by forwarding through the
  public `omarchy-shell` IPC boundary instead of a cross-plugin service lookup.
- Bound OSD payload size, display fields, numeric values, and duration before
  forwarding or rendering untrusted IPC input.
- Cover scoped-shell forwarding, fallback, rapid updates, explicit close, and
  input bounds in the runtime conformance suite.

## 0.2.0 - 2026-09-09

- Follow the stock bar to left and right edges while preserving the horizontal
  Peek, transient, keyboard, provider, and stock-panel behavior.
- Anchor Island-owned detail inward from the live vertical Rest position.

## 0.1.1 - 2026-09-08

- Keep stock panel, widget, and adapter routing working on Omarchy 4.0.3's
  scoped third-party shell facades.

## 0.1.0 - 2026-08-29

- Ship Omarchy Island as one movable widget in the stock Omarchy bar.
- Include clock, workspace, tray, status, audio, display, and stock-panel adapters.
- Bundle Now Playing, Reminders, Screen Recording, and System Update activities.
- Support Island-aware third-party quick access and activity providers.
- Provide keyboard navigation, focused-monitor routing, TOML configuration, and diagnostics.
- Keep the stock Omarchy OSD unchanged unless the optional companion is explicitly enabled.
- Validate schema version 1 registrations, declared actions, provider failback,
  and provider-owned event cleanup.
- Support documented multiline configuration arrays.
- Bound screen-recording finalization and make the optional OSD install
  rollback-safe and removable.
