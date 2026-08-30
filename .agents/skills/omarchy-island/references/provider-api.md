# Provider API reference

## Registration

Island discovers only enabled Omarchy plugins with an `omarchyIsland` manifest object. A `bar-widget` entry point alone is not registration.

For quick access to an existing surface:

```json
{
  "omarchyIsland": {
    "schemaVersion": 1,
    "id": "acme.notes",
    "capabilities": ["quick-access"],
    "displayName": "Notes",
    "fallbackGlyph": "N",
    "quickAccess": {
      "enabled": true,
      "id": "acme.notes",
      "target": "acme.notes",
      "label": "Notes",
      "glyph": "N"
    }
  }
}
```

For an activity provider, add `entryPoints.omarchyIslandProvider` and the `activity-provider` capability. The fixed optional presentation entry points are `omarchyIslandMinimal`, `omarchyIslandCompact`, `omarchyIslandExpanded`, and `omarchyIslandEvent`.

## Provider object

The host creates the provider and injects:

- `island`: semantic publish/update/withdraw and host routing API.
- `manifest`: the plugin manifest.
- `providerId`: `omarchyIsland.id`, falling back to the plugin ID.
- `shell`: injected only when the provider declares that property.
- `pluginRegistry`: injected only when declared.

Implement idempotent `start()` and `stop()` functions. The host calls `start()` after creation. On disable or removal it calls `stop()`, withdraws all provider activity, and destroys the object. Providers should still withdraw their own activity and stop timers/processes in `stop()`.

Handle actions with `onAction(activityId, actionId)`. Actions must be typed IDs declared by the activity; do not pass shell command strings through activity data.

## Semantic activity

Publish with:

```qml
island.publish(providerId, {
  id: "sync",
  title: "Syncing",
  subtitle: "3 files remaining",
  glyph: "S",
  attention: "routine",
  progress: 0.7,
  updatedAt: Date.now(),
  leaseMs: 30000,
  presentation: { rest: "companion" },
  primaryAction: "open",
  actions: [{ id: "open", label: "Open sync" }],
  data: { remaining: 3 }
})
```

Required in practice: stable `id`, useful `title`, and a fallback `glyph`. The host normalizes omitted fields.

- `attention`: `routine`, `timely`, or `critical`.
- `progress`: real progress from the underlying system. Omit it rather than animating fake progress.
- `expiresAt`: absolute milliseconds (or seconds, normalized by the host).
- `leaseMs`: expiry relative to `updatedAt`.
- `presentation.rest`: `hidden`, `companion`, or `takeover`. This is a preference; user configuration and host arbitration remain authoritative.
- `primaryAction`: the ID of one declared action. Rest/Peek pointer and keyboard activation route it directly. An absent or invalid value opens Activity Focus.
- `event`: a semantic event object. A new `event.id` asks the host to present it once.

Use `island.update(providerId, activityId, patch)` for partial changes and `island.withdraw(providerId, activityId)` when the underlying state stops. Republishing the same stable key replaces its semantic state.

## Presentation boundary

Custom presentation is optional trusted QML. The host injects activity and provider context, while retaining the outer surface, geometry, focus, dismissal, border, animation, and fallback behavior. A failed or disabled custom view must leave the activity usable.

Use the levels deliberately:

- Minimal: Rest companion/takeover mark.
- Compact: Peek representation.
- Expanded: Activity Focus content.
- Event: short-lived event interior.

Start with `providers/system-update/`. It has no custom presentation and proves the complete discovery, lifecycle, semantic activity, and primary-action path.

## Verification checklist

- Plugin and provider IDs are stable and distinct where appropriate.
- Manifest declares only entry points that exist.
- Provider is inert until `start()` and fully cleans up in `stop()`.
- External commands are bounded and errors do not publish stale state.
- Activity withdraws when the real underlying state ends.
- Every `primaryAction` matches a declared action.
- Declarative fallback remains usable without custom QML.
- `./scripts/check` passes.
- A live `omarchy-shell omarchy-island inspect` read-back shows the expected provider/activity state when live installation is in scope.

For an agent-readable lifecycle check, inspect `.providerDiagnostics`. Locate
the record by `pluginId` or `providerId`, require `status == "loaded"` for an
activity provider, and confirm its `activities` after the underlying state is
active. A `disabled` record includes a `reason`; a `failed` record includes an
actionable `error`. Do not trigger a provider action merely to prove discovery.
