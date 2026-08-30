# Provider implementation checklist

The canonical schema, examples, field semantics, and diagnostics contract live
in [`docs/plugin-api.md`](../../../../docs/plugin-api.md). Read that document before
changing a provider. This checklist adds agent-oriented implementation checks;
it does not redefine the API.

## Choose the smallest shape

- Quick access: existing panel or application, no ongoing state.
- Declarative activity: ongoing or event-like state using the host fallback.
- Custom presentation: only for a level whose layout materially needs it.

Copy `providers/system-update/` for the minimal provider shape. Consult Screen
Recording for a primary action and event, Reminders for deadlines and multiple
records, and Now Playing only for a genuinely rich presentation.

## Lifecycle and actions

- Keep plugin and provider IDs stable.
- Make `start()` and `stop()` idempotent.
- Stop every timer/process and withdraw all activity from `stop()`.
- Bound external commands and recover without stale activity.
- Publish a stable activity `id`, useful `title`, and fallback `glyph`.
- Use real progress only; omit unknown progress.
- Declare every action in `actions` before routing it.
- Point `primaryAction` at one declared action or omit it.
- Return `false` from `onAction` only when the provider rejects the request.

## Verify

1. Run `./scripts/check`.
2. Inspect `omarchy-shell omarchy-island inspect`.
3. Require the expected `providerDiagnostics` status, owner, and activity keys.
4. Disable and re-enable the plugin; verify activity withdrawal and recovery.
5. Do not trigger system updates, recordings, or another externally visible
   action merely to prove discovery.
