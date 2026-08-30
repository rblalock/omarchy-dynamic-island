# Optional OSD companion

The normal Omarchy Island install does not change `omarchy.osd`. The OSD
companion is a separate, explicitly enabled plugin for users who want Omarchy's
existing on-screen feedback to morph through Island instead of also appearing
in the stock bottom card.

## Enable and restore

```bash
~/.config/omarchy/plugins/rblalock.omarchy-island/scripts/osd-companion-enable
```

The companion manifest declares `omarchy.clonedFrom = "omarchy.osd"`.
Omarchy's own plugin registry therefore disables the stock presenter while the
companion is enabled and records that it must restore the source later.

```bash
omarchy plugin disable rblalock.omarchy-island-osd
```

Disabling the companion restores `omarchy.osd`; it does not edit packaged
Omarchy files or permanently disable OSD feedback. It intentionally leaves the
managed companion copy installed so it can be enabled again. Remove that copy
and restore the stock presenter with:

```bash
~/.config/omarchy/plugins/rblalock.omarchy-island/scripts/osd-companion-remove
```

Installing or updating the main Island plugin alone never enables this
replacement.

## Supported contract

The companion owns the same `osd` IPC target and accepts the stock JSON fields:

| Field | Behavior |
|---|---|
| `icon` | Stock semantic icon name or an arbitrary glyph. |
| `message` | Text event. A non-empty message selects message mode. |
| `value` | Numeric progress value. Progress mode requires an empty message. |
| `max` | Progress maximum; defaults to `100`. |
| `progressText` | Optional readout instead of the calculated percentage. |
| `duration` | Milliseconds before dismissal; defaults to `1200`, while `0` remains until an explicit close. |

This covers the current Omarchy producers for output volume and mute, input
mute, audio-output switching, monitor brightness, keyboard backlight,
touchpad/touchscreen state, media controls and source changes, application
launch feedback, video-download progress, logout/reboot/shutdown status, and
arbitrary `omarchy osd` calls. New producers that use the same stock payload
contract require no Island-specific adapter.

## Arbitration and fallback

The companion resolves `rblalock.omarchy-island` on every event and asks the
focused monitor's Island host to accept it. The first update in an OSD sequence
latches that monitor until the event closes or expires; changing focus during
volume repeats does not teleport the transient. If the latched monitor is
removed, Island clears the event and the next update can choose another host.
Islands on other monitors continue showing their normal Rest content.

Passive pointer Peek yields to an accepted OSD, then returns immediately when
the transient ends if the pointer remains over Island. Keyboard-open Peek,
Shelf, Focus, Controls, and provider events are explicit user or semantic
ownership and are never displaced by routine OSD feedback.

If Island is missing, still loading, owned by one of those retained surfaces,
or rejects malformed input, the companion retains a stock-style bottom OSD.
Duration `0` and explicit `close` work on either route. That fallback is part
of the replacement rather than a second simultaneous presenter.

Island-owned wheel and slider actions continue using the first-party Audio and
Display transients directly. External hardware and system-script changes are
not inferred from raw state changes; they arrive through the OSD contract.
This gives each change one presentation owner and avoids an Island animation
immediately followed by another Island animation for the same action.

## Inspection and safe testing

The current normalized event is available without opening another UI:

```bash
omarchy-shell omarchy-island inspect \
  | jq '.transient | {active, kind, osdScreen, osdArbitration, osd}'
```

A harmless contract check can be sent directly to Island without enabling the
companion or changing system state:

```bash
omarchy-shell omarchy-island osdShow '{"icon":"brightness","value":70}'
omarchy-shell omarchy-island osdClose
```

`./scripts/check` validates the root plugin and companion manifest template,
normalization, focused-monitor routing, progress/message lifecycle, rejection while a retained surface owns
the Island, direct companion forwarding, fallback parity, explicit close, and
installer rollback after a failed enable.
