# Island plugin integration

Island discovers enabled Omarchy plugins through the namespaced
`omarchyIsland` object in their existing `manifest.json`. A normal `bar-widget`
entry point does not register the plugin with Island.

Choose the least powerful integration that preserves the behavior: quick
access for an existing surface, a declarative provider for ongoing state, and
custom presentation QML only when the host fallback is insufficient. The
smallest complete provider is [`providers/system-update/`](../providers/system-update/);
do not copy every entry point from the richer examples by default.

## Quick access

Use quick access when the plugin already has a summonable panel, overlay, menu,
or application surface:

```json
{
  "omarchyIsland": {
    "schemaVersion": 1,
    "id": "acme.notes",
    "capabilities": ["quick-access"],
    "displayName": "Notes",
    "fallbackGlyph": "󰠮",
    "quickAccess": {
      "enabled": true,
      "target": "acme.notes",
      "label": "Notes",
      "glyph": "󰠮"
    }
  }
}
```

When the plugin is enabled, Island adds this item to Peek and Controls. Its
primary action closes Island and summons `target` through the stock shell.
Disabling or removing the plugin removes the item on the next registry scan.

## Activity provider

Use an activity provider for state that continues over time, such as media,
recording, timers, downloads, reminders, calls, or navigation:

```json
{
  "entryPoints": {
    "omarchyIslandProvider": "island/Provider.qml",
    "omarchyIslandCompact": "island/Compact.qml",
    "omarchyIslandExpanded": "island/Expanded.qml"
  },
  "omarchyIsland": {
    "schemaVersion": 1,
    "id": "acme.timer",
    "capabilities": ["activity-provider", "custom-presentation"],
    "displayName": "Timer",
    "fallbackGlyph": "󰔛"
  }
}
```

The host creates `omarchyIslandProvider`, injects `island`, `manifest`, and
`providerId`, then calls `start()`. Providers publish semantic activity with
stable IDs and route typed actions through `onAction(activityId, actionId)`.
Optional custom QML owns only interior presentation; Island continues to own
the window, outer geometry, focus, dismissal, and fallback.

An activity may set `primaryAction` to the ID of one of its declared `actions`.
Island validates the reference and routes Rest/Peek pointer or keyboard
activation through `onAction`; if the reference is absent or invalid,
activation opens Activity Focus. This is intended only for established
single-click semantics such as stopping a screen recording. Provider QML still
does not intercept or redefine the Island's outer click target.

An activity can provide a host-level Rest hint alongside its semantic state:

```qml
island.publish(providerId, {
  id: "timer",
  title: "12:08 remaining",
  presentation: { rest: "companion" }
})
```

`presentation.rest` accepts `hidden`, `companion`, or `takeover`; invalid and
missing values normalize to `takeover` for compatibility. In `auto` mode, a
companion is rendered at icon scale beside the clock. The hint does not assign
priority, bypass arbitration, own outer geometry, or displace a provider event.
Users can override the hint per provider under `[providers.rest]`; providers
must therefore treat it as a preference rather than guaranteed placement.

When several activities are ongoing, the host still renders only the leading
activity at Rest. Opening Activity Focus exposes the ranked set and lets the
user select another activity. Providers do not need to coordinate with one
another or build their own activity switcher.

## Built-in adapters

Island's own `layout.peek` list accepts only IDs for which the host ships an
adapter. Unsupported IDs are diagnosed and omitted. Supporting another stock
or third-party widget therefore means either:

- adding and maintaining a host adapter in this repository; or
- adding `omarchyIsland` metadata and, when needed, provider code to that plugin.

This boundary prevents guessed icons and dead actions while allowing the
plugin ecosystem—or a user's local coding agent—to add support independently.

## Bundled reference providers

Now Playing is the reference implementation for the stable schema version 1
activity-provider contract. It exercises start/stop lifecycle,
semantic state, typed media actions, declarative fallback, optional compact and
expanded QML, reduced motion, and failure recovery. Its implementation remains
independent of Island internals so plugin authors and coding agents can use it
as the canonical starting point.

The host's built-in volume and brightness adapters may later move behind this
same semantic boundary. They remain host-owned until doing so preserves their
current scroll, transient, Focus, and stock-panel handoff behavior.

The reference lives in [`providers/now-playing/`](../providers/now-playing/)
and is loaded automatically by the root Island service. The other reference
providers use the same host contract. A third-party plugin supplies the
corresponding `omarchyIsland` manifest metadata shown above; it does not copy
or modify the host.

It reads MPRIS player state, publishes stable semantic updates and real track
progress when available, and routes explicit previous, play/pause, and next
actions. The compact visual is identified as `playback-progress`: it presents a
static, optically centered music note inside a real track-progress halo. The
note is full strength while playing and dimmed when paused; the halo advances
without looping animation. Track artwork is reserved for the expanded
presentation, avoiding decorative motion and misleading browser artwork in the
bar. `Paused` remains an ongoing resumable activity; `Stopped` withdraws the
activity even when a browser leaves its MPRIS object and metadata behind.

The second reference lives in [`providers/reminders/`](../providers/reminders/).
It consumes the structured output of Omarchy's existing reminder command and
never schedules a parallel timer. One stable activity represents the next
deadline while its data carries every outstanding reminder for expanded Focus.
New, Show, and Clear remain typed actions routed to Omarchy's existing reminder
surfaces and commands. An empty reminder set withdraws the activity.

The third reference lives in
[`providers/screen-recording/`](../providers/screen-recording/). It observes
Omarchy's existing recorder process and generated destination path, publishes a
renewed ongoing activity with real process elapsed time, and routes Stop through
the mark's validated `primaryAction` to the stock command that safely finalizes
the video and sends the normal Omarchy notification. Its compact presentation
is deliberately icon-only and it supplies no custom expanded view. A successful
provider-routed stop emits one saved event; an external stop withdraws the
activity without claiming finalization it did not observe.

The fourth reference lives in
[`providers/system-update/`](../providers/system-update/). It is intentionally
the smallest complete provider: one provider QML file, declarative activity
fields, and a validated primary action. It ships no custom presentation entry
points. The provider reads Omarchy's bounded availability command, follows the
stock widget's live boolean when that widget is mounted, and launches the same
floating-terminal updater as the stock bar control.

## Diagnostics

The host exposes provider discovery and lifecycle state through the existing
read-only inspector:

```bash
omarchy-shell omarchy-island inspect | jq '.providerDiagnostics'
```

Each record contains `pluginId`, `providerId`, `displayName`, `sourceDir`, the
provider entry point and resolved URL, declared capabilities and presentation
levels, `quickAccessId`, active `activities`, and a lifecycle `status`:

- `discovered`: valid Island metadata or quick access with no provider object.
- `loaded`: the provider object was created and `start()` completed.
- `disabled`: the source plugin is disabled or the provider ID is disabled by
  Island configuration; `reason` identifies which boundary suppressed it.
- `superseded`: an enabled external plugin owns the same provider ID as a
  bundled reference, so the external implementation is active.
- `failed`: provider resolution, QML loading, object creation, startup, or ID
  ownership failed; `error` contains the actionable failure.

Bundled diagnostics additionally set `bundled: true` and use the root Island
plugin ID as their source. This makes a one-command installation inspectable
without representing the built-in implementations as separately installed
plugins.

The existing `providers`, `quickAccess`, and `activities` arrays remain as
compact compatibility summaries. Inspect diagnostics before adding fallback
logic: a failed provider should be repaired at its source, while a disabled
provider should not be force-loaded.
