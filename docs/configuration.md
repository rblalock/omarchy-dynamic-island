# Configuration

Omarchy Island merges user overrides from `~/.config/omarchy/island.toml` over
[the repository defaults](../config/default.toml) and hot-reloads both. A user
file only needs the values it changes. The parser supports the TOML forms used
here: tables, quoted keys, strings, booleans, numbers, and single- or multiline
arrays. Numeric geometry values use Omarchy's theme-scaled spacing, except an
explicit `corner_radius`, which is a direct pixel value matching Hyprland.

## Placement and appearance

Island is a normal bar widget and therefore appears on every connected monitor
where Omarchy renders its bar. Placement within each bar comes from
`shell.json`; actions and retained detail resolve on the focused monitor.

| Key | Default | Behavior |
|---|---:|---|
| `placement.top_offset` | `0` | Non-negative distance from the top edge for retained detail on a horizontal bar. Vertical detail follows the live Island anchor instead. |
| `appearance.style` | `"system"` | `system` inherits Hyprland corner geometry. `pill`, `soft-square`, and `outline` remain explicit visual choices. |
| `appearance.shelf_width` | `430` | Shared retained width, capped to the screen. |
| `appearance.shelf_height` | `0` | Minimum Shelf height; `0` follows active content and oversized content scrolls. |
| `appearance.focus_height` | `224` | Provider Focus height. |
| `appearance.controls_height` | `318` | All Controls height. |
| `appearance.corner_radius` | `"system"` | Inherits Omarchy's live `Style.cornerRadius`, sourced from Hyprland `decoration:rounding`. A non-negative number explicitly overrides it in pixels. |
| `appearance.clock_format` | `"h:mm AP"` | Qt date/time format. |
| `appearance.clock_format_vertical` | `"HH\nmm"` | Compact two-line Qt date/time format used at Rest on a left or right bar. |
| `appearance.background` | `""` | QML color override. Empty uses the popup background while open and inherits the stock bar's live transparency while at Rest. |
| `appearance.border` | `""` | QML color override; empty inherits the popup border. |
| `appearance.allow_custom_qml` | `true` | Enables optional trusted provider views; declarative fallback remains available when false. |

With no explicit `appearance.background`, double-clicking empty stock-bar space
keeps the collapsed Island visually in sync with Omarchy's transparent mode.
Revealing Peek or presenting a transient fades the Island background and
boundary back in so its controls remain legible. An explicit background
override opts out of this inheritance.

## Behavior, keyboard, and motion

| Key | Default | Behavior |
|---|---:|---|
| `behavior.collapse_delay_ms` | `95` | Delay before Peek returns to Rest after pointer exit. |
| `behavior.event_hold_ms` | `4500` | Semantic event hold, clamped to at least 250 ms. |
| `behavior.auto_focus_events` | `false` | Opens activity Focus for a new provider event ID. |
| `behavior.keyboard_target` | `"peek"` | Destination toggled by `omarchy-shell omarchy-island keyboard`; `peek` retains the same bar-hosted inventory shown on hover, `controls` opens All Controls, and values such as `workspaces`, `tray`, `status`, or `activity` open that Detail. |
| `motion.enabled` | `true` | Enables geometry/content transitions. |
| `motion.reduced` | `false` | Removes spatial motion when true. |
| `motion.expand_ms` | `260` | Width/height entrance duration, using a smooth cubic deceleration. |
| `motion.collapse_ms` | `180` | Faster cubic collapse duration. |
| `motion.content_ms` | `150` | Fade and radius duration. |

`omarchy-shell omarchy-island controls` opens Controls directly. The default
`keyboard` target retains the exact horizontal Peek shown on hover. On a top or
bottom bar it grows within the bar; on a left or right bar the same surface
grows inward over the desktop from the bar-hosted Rest anchor. Arrows or
`h/j/k/l` move through those proxy controls and spatially through retained
details; `Tab` and `Shift+Tab` follow the focus chain; `Home` and `End` move to
its bounds; `Enter` or `Space` activates; and `Escape` closes. While the
top-level Peek has keyboard focus, `1` through `9` activate the corresponding
displayed item and `0` activates the tenth. These shortcuts follow the current
rendered order and do not replace directional navigation. A pointer can take
over the focused item without making keyboard-open Peek collapse on exit.
Audio keeps Left/Right and `h/l` for adjustment while its slider is focused,
with `j/k` available to leave it. `OMARCHY_ISLAND_REDUCED_MOTION=1` also
disables spatial motion. Old spring, bounce, and general duration keys are
ignored.

## Layout

Island uses one standalone interactive bar entry and does not adopt or relocate
other bar widgets:

```json
{ "id": "rblalock.omarchy-island" }
```

`layout.peek` selects and orders Island's built-in adapters. It is not a mirror
of the stock bar. An ID without a built-in adapter is reported under
`unsupportedPeek` by `inspect` and is not rendered.

The root plugin automatically starts its bundled Now Playing, Reminders,
Screen Recording, and System Update providers. Enabled third-party plugins
join independently when their manifest declares `omarchyIsland.quickAccess`,
or while their activity provider publishes state. Ordinary `bar-widget`
registration does not opt a plugin into Island. Clock, status indicators, and
keyboard layout have narrow compatibility bridges when their visible stock
widget is absent because Omarchy does not yet expose those behaviors as
independent services; Island does not use that mechanism for discovery.

`layout.rest_content` accepts `clock`, `activity`, or `auto`. `clock` always
uses the clock at Rest. `activity` shows the leading activity when present. The
default `auto` honors the leading provider's validated
`presentation.rest`: `companion` shares Rest with the clock, `takeover`
replaces it, and `hidden` leaves the clock alone. Provider events take over
regardless of a companion hint. Volume and brightness transients temporarily
replace the resulting Rest composition and restore it when their hold ends.

The default built-in selection can be overridden explicitly:

```toml
[layout]
include_clock = true
rest_content = "auto"
peek = [
  "omarchy.menu",
  "omarchy.workspaces",
  "omarchy.tray",
  "omarchy.indicators",
  "omarchy.bluetooth",
  "omarchy.network",
  "omarchy.audio",
  "omarchy.power",
]
```

Built-in support covers launcher, workspaces, tray, status, Tailscale,
Bluetooth, network, keyboard layout, power, audio, display, and weather. The
stock system-update adapter remains available for explicit configurations, but
the bundled System Update provider is the only default projection, preventing
duplicate update controls. Some controls delegate to stock anchors;
workspaces, tray, status, audio, and display have Island-owned retained views.
Availability rules hide conditional controls such as battery power when
inactive.

`workspaces.count` defaults to `10`, matching Omarchy's `SUPER+1` through `SUPER+0` workspace bindings. The shelf always shows that complete range; set another positive count for a different workspace model.

## First-party adapters

| Key | Default | Behavior |
|---|---:|---|
| `adapters.audio.enabled` | `true` | Uses the Island-native volume adapter when the live stock audio widget exposes the required state and actions. Otherwise Audio delegates to the stock panel. |
| `adapters.audio.transient_hold_ms` | `1600` | Volume transient hold, clamped to at least 250 ms. Retained views, Peek, and provider events are not displaced. |
| `adapters.audio.scroll_step_percent` | `5` | Output-volume change per complete wheel step over the Peek Audio target, clamped from 1 to 25 percent. |
| `adapters.display.enabled` | `true` | Uses the Island-native brightness adapter when the live stock monitor widget exposes brightness state and actions. Otherwise Display delegates to the stock panel. |
| `adapters.display.transient_hold_ms` | `1600` | Brightness transient hold, clamped to at least 250 ms. Retained views, Peek, and provider events are not displaced. |
| `adapters.display.scroll_step_percent` | `5` | Brightness change per complete wheel step over the Peek Display target, clamped from 1 to 25 percent. |

The audio and display adapters consume live stock widgets rather than owning PipeWire or monitor hardware independently. This preserves Omarchy's output resolution and hardware-specific brightness behavior while making compatibility feature-detectable. The full stock mixer and display panel remain available from their Focus views.

## Providers

| Key | Default | Behavior |
|---|---:|---|
| `providers.order` | `[]` | Preferred provider IDs after the critical safety floor and pins. |
| `providers.pinned` | `[]` | Provider IDs preferred at Rest and when Activity Focus first opens. Critical activities still win. |
| `providers.disabled` | `[]` | Bundled or external provider IDs the host does not start or display. |
| `providers.custom_qml_disabled` | `[]` | Provider IDs restricted to declarative presentation. |
| `providers.rest.<provider-id>` | unset | Overrides a provider's Rest hint with `hidden`, `companion`, or `takeover`. |

The host applies the critical safety floor first, followed by user pins,
provider order, `critical`/`timely`/`routine` attention, and recent update.
Opening Activity Focus shows the leading activity and, when more than one is
ongoing, an icon rail for selecting the others with pointer or keyboard.

Provider IDs contain dots, so Rest override keys are quoted TOML strings:

```toml
[providers]
pinned = ["acme.timer"]
order = ["acme.timer", "rblalock.now-playing"]

[providers.rest]
"acme.timer" = "takeover"
"rblalock.now-playing" = "companion"
```

The override is user policy; it takes precedence over the provider's
`presentation.rest` hint without changing the published activity. Invalid
override values are ignored. Expiry and leases are honored. A changed non-empty
`event.id` starts event presentation; ordinary updates with the same ID do not
retrigger it. Disabling custom QML leaves actions available through the
declarative fallback.

## Safe disable

```bash
omarchy plugin disable rblalock.omarchy-island
```

Disabling `rblalock.omarchy-island` does not alter the stock layout or delete
the checkout or user configuration.
