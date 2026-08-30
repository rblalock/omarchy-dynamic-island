# Omarchy Island Brainstorm

Status: product and UX exploration. This document records accepted direction,
working proposals, future ideas, and unresolved questions. It is intentionally
broader than the first implementation slice.

## Current reset baseline

- The normal Omarchy bar is restored with its standard widgets in their
  original sections.
- Omarchy Island is one ordinary, draggable bar widget beside them.
- The widget owns a small clock Rest state, a horizontal proxy inventory on
  hover or `SUPER+R`, and the existing morphing detail views.
- The original bar widgets remain visible and mounted exactly where Omarchy put
  them; Island does not adopt, move, or duplicate their QML components.
- Peek contains only configured first-party adapters plus enabled plugins that
  explicitly declare Island quick access or publish an Island activity.
- Ordinary bar registration does not imply Island support. Unsupported widgets
  stay out instead of receiving a guessed fallback.
- The earlier nested-container/adoption prototype was rejected and removed.

## Product idea

Omarchy Island is a single, minimal surface at the top center of the desktop.
At rest it is a small clock. It progressively reveals navigation, status,
controls, launchers, activities, and system events by morphing rather than by
keeping a conventional full-width top bar visible.

The long-term ambition is for the Island to consolidate the useful behavior of
the Omarchy top bar and related shell surfaces. It should preserve the existing
functionality of Omarchy widgets instead of gratuitously rebuilding Bluetooth,
network, audio, display, power, weather, tray, and similar system UI.

The Island should become better as plugins opt in. Plugins with Island support
can provide purpose-built semantic state, quick access, and richer morphing
presentations. Plugins without Island support stay in the stock shell.

## Accepted direction

- The product name is **Omarchy Island**.
- The resting presentation keeps the clock as its base and may add one
  provider-declared companion.
- Hover reveals the current supported Island inventory.
- Clicking the resting pill opens launcher/search.
- Clicking a revealed item invokes that item directly.
- Existing Omarchy panels and actions should be reused wherever practical.
- Integration is progressive and pluggable rather than all-or-nothing.
- Island can ship first-class adapters for default Omarchy plugins.
- A user-open surface must not be displaced by routine volume, brightness, or
  notification events.
- The bar-hosted Island appears on every connected monitor; actions and retained
  detail target the focused monitor.
- During development, the existing Omarchy bar stays enabled and its widgets
  are never relocated by Island.
- Retained companion surfaces float from the top center without replacing the
  bar or claiming a second persistent desktop zone.
- Any future stock-bar replacement requires a separate, explicit decision and
  a tested, immediate fallback.

## Product principles

1. **Preserve behavior before improving presentation.** Existing widget
   functionality is the baseline contract.
2. **Explicit enhancement.** A plugin appears only through a first-party
   adapter or its own Island registration; unsupported plugins remain in the
   stock shell.
3. **The host owns the shell experience.** Geometry, motion, focus, priority,
   dismissal, accessibility, and fallbacks remain coherent across plugins.
4. **Plugins own their domain.** A plugin provides state, actions, and optional
   presentation without taking over top-level windows or global arbitration.
5. **User intent outranks ambient events.** Explicitly opened UI remains stable.
6. **Minimal at rest, complete on demand.** Consolidation must not become
   permanent information density.
7. **Reversible development.** Island must be independently disableable, and
   the stock shell must remain recoverable.
8. **Omarchy-native by default.** Theme, type, spacing, focus language, and
   controls should follow the current Omarchy theme.

## Core interaction states

| State | Purpose | Entry | Exit |
|---|---|---|---|
| Rest | Tiny clock-only pill | Idle/default | Hover, click, shortcut, or event |
| Peek | Reveal bar-like navigation and status targets | Brief hover | Pointer leaves after a forgiving delay |
| Focused | Show the selected widget or activity | Click a revealed target | Escape, outside click, completion, or another explicit selection |
| Transient | Briefly show volume, brightness, media, notification, timer, update, or recording state | System/activity event | Timeout, dismissal, or user expansion |
| Launcher | Keyboard-capable application/search surface | Click rest state or direct shortcut | Launch, Escape, or outside click |
| Control center | Group common system controls | Click expanded empty space, status cluster, or direct shortcut | Escape or outside click |
| Secure modal | Real authentication or other non-optional system flow | System request | Success, failure, or explicit cancellation |

The surface should remember the prior state. When a temporary presentation
ends, it returns to the user-open state if one exists, otherwise to peek while
the pointer remains present, and finally to rest.

## Mouse and keyboard behavior

Working proposal:

- Hover for roughly 150 ms expands rest into peek. Exact timing should be
  configurable after testing.
- Leaving the Island starts a forgiving collapse delay so the surface does not
  twitch when crossing into a panel.
- Clicking the resting clock preserves stock-bar parity by opening Omarchy's
  existing calendar panel. Launcher/search remains the menu proxy's action.
- Clicking a revealed icon opens that plugin's standard or enhanced surface.
- Clicking an active transient expands to the relevant detail when available.
- Clicking empty space in the expanded hover surface opens the control center.
- Right-click opens Island settings/management.
- Escape and outside click close the active non-secure surface.
- Scroll only has meaning over an explicit target such as workspaces, volume,
  brightness, or media. There is no ambiguous global scroll action.
- Important surfaces retain direct keyboard shortcuts. Hover is never the only
  route to functionality.
- Keyboard focus must be visible, predictable, and trapped only while a modal
  or focused Island surface genuinely needs it.
- Direct keyboard entry retains the familiar horizontal Peek rather than
  introducing the labeled Controls grid. Arrows and `h/j/k/l` traverse the
  one-dimensional inventory, Enter/Space activates, pointer hover may take
  over selection, and Escape closes. `SUPER+R` is the recommended default
  binding when unclaimed.
- Morph targets preserve the same keyboard session: retained shelves, Focus
  views, and Controls use spatial arrows or `h/j/k/l`, with pointer hover able
  to take over selection. Audio reserves Left/Right and `h/l` for its focused
  slider while `j/k` moves to neighboring controls.
- Reduced-motion mode changes state without spring animation but preserves all
  content and actions.
- Hovered controls use tonal fill without nested outlines. Keyboard focus uses
  a stronger fill plus a short inset accent chin whose fixed geometry never
  changes control size, content position, or surrounding layout. Persistent
  current/on state remains a separate selected fill.

## Hover inventory

The first hover presentation can preserve the current top-bar ordering and
interaction model:

```text
menu · workspaces
  | indicators · keyboard layout · clock · weather · update
  | tray · tailscale · bluetooth · network · audio · display · power
```

This is the current built-in adapter catalog, not a promise to mirror the
user's bar. It may prove too wide. If so, the next design is a grouped peek:

- workspace/navigation group;
- current activity or context;
- glanceable indicators;
- system-status group;
- explicit control-center affordance.

The rest state must remain quiet even if the hover state grows. A validated
provider companion may share Rest with the clock; ordinary activities remain
in Peek/Focus, while explicit takeovers and semantic events may replace Rest.
First-party volume and brightness transients replace the complete Rest
composition only for their short hold, then restore it.

## Progressive plugin integration

Island integration has three useful levels.

### What is dynamic and what is code-defined

The host is intentionally neither a fixed replica of one desktop nor a fully arbitrary layout engine.

**Dynamic at runtime:**

- configured built-in adapter selection and ordering;
- enabled-plugin rescans, explicit Island quick access, and providers;
- string-backed plugin icons/labels and plugin-native Island presentations;
- focused monitor, active workspace, occupancy, tray applications, and indicator state;
- live Omarchy colors, typography, spacing, icon metrics, and Hyprland corner radius;
- audio output volume, mute state, output label, and feature availability;
- TOML geometry, motion, layout, provider policy, workspace count, and adapter settings.

**Code-defined in the host:**

- Rest/Peek/Transient/Shelf/Focus/Controls state semantics and priority;
- host geometry, focus, dismissal, accessibility, animation, and failure rules;
- first-party adapter IDs and their compatibility probes into current Omarchy widgets;
- built-in labels, glyphs, the known status catalog, and stock handoff behavior;
- host-owned QML for shelves, transient views, and first-party Focus adapters;
- supported configuration keys, defaults, validation bounds, and inspection output.

This boundary lets another user's theme and explicitly registered plugins flow
into Island while keeping the interaction model coherent. A new plugin appears
only after it declares quick access or an activity provider. An Omarchy widget
whose internal contract changes is hidden when its adapter can no longer offer
a valid interaction.

### Level 1: Island-provided adapter

Omarchy Island can provide first-class adapters for important default Omarchy
features. An adapter can reuse an existing service/model and expose:

- semantic compact state;
- explicit typed actions;
- a host-native expanded view;
- transient/event state;
- better morph geometry than the generic handoff;
- a declarative fallback if enhanced QML is unavailable.

Likely early adapters include audio/volume, brightness/display, media,
notifications, system update, recording, and reminders. Bluetooth, network,
weather, power, workspaces, and tray follow according to what standard widget
reuse proves insufficient.

### Level 2: plugin-native Island support

A plugin may declare an Island integration contract. The exact API remains to
be finalized, but the existing provider ideas are still useful:

- a semantic provider entry point;
- optional compact presentation;
- optional expanded presentation;
- optional event presentation;
- typed labeled actions;
- stable activity and event identifiers;
- lifecycle/expiry metadata;
- accessibility labels and a declarative fallback.

Candidate manifest keys from the earlier prototype include
`omarchyIslandProvider`, `omarchyIslandCompact`, `omarchyIslandExpanded`, and
`omarchyIslandEvent`. These are candidates, not yet a frozen public API.

Integration precedence should be:

1. valid plugin-native Island integration;
2. Island-provided adapter for that plugin/feature;
3. standard registered-widget or target handoff;
4. disabled/unavailable fallback with a clear diagnostic.

The host must be able to reject a broken custom view and fall back without
losing access to the underlying action.

## Existing UI reuse and morphing

Reuse and in-place morphing are separate milestones.

### Standard handoff

Island shows the plugin icon, performs a standard selection animation, and
opens the existing Omarchy surface. This preserves behavior with minimal
integration work.

### Connected morph

Island grows toward or visually connects to the existing popup so the handoff
reads as one transition, even though the popup remains its own surface.

### True in-place morph

The Island becomes the selected UI. This normally requires panel content to be
usable separately from its current popup window. It should be reserved for
plugin-native support or a deliberate first-party adapter rather than achieved
through brittle reparenting.

The goal is to improve gracefully:

- unsupported plugin: standard handoff;
- supported plugin: connected or true morph;
- default Omarchy plugin: first-class support supplied by Island where useful.

## Development and replacement modes

### Historical overlay development mode (superseded)

This was the safe initial prototype and is no longer the active architecture.

- Keep `omarchy.bar` active.
- Do not disable, remove, reorder, or relocate existing widgets.
- Render Island as a top-center overlay with no exclusive zone.
- Keep Island independently enableable and disableable.
- Start on the focused monitor.
- Use lightweight proxy items to invoke existing stock-bar widget instances.
- Accept that an existing panel may initially anchor to its original stock-bar
  icon rather than the Island proxy.
- Never kill the shared `omarchy-shell` merely to stop Island.

This mode proves state, layout, motion, hover, launcher routing, event priority,
and feature coverage without risking the working desktop.

### Replacement test mode

Before changing the live bar, use a disposable harness or an explicitly
requested test mode in which Island acts as a custom bar and loads registered
widgets itself. A custom bar must supply the compatibility surface existing
widgets expect, including:

- theme and geometry properties;
- widget registry loading and property injection;
- tooltip coordination;
- one-popout-at-a-time coordination;
- per-monitor widget enumeration and routing;
- panel switching and keyboard navigation;
- shell configuration access where required;
- correct popup anchor windows.

### Optional live replacement

Live replacement is a later product decision, not an automatic milestone. It
requires:

- explicit user approval;
- a parity review of every configured widget;
- a one-command fallback to the stock bar;
- preserved configuration and plugin files;
- crash/failure fallback behavior;
- multi-monitor and focus proof;
- fresh-load proof after shell restart;
- no packaged-file modifications under `/usr/share/omarchy`.

## Event arbitration

Initial visual priority:

```text
secure system modal
  > explicit user-open surface
  > critical actionable event
  > active semantic activity/event
  > routine transient/notification
  > rest
```

Rules:

- Routine volume, brightness, media progress, and notifications never replace
  a user-open panel.
- While a user surface is open, a routine transient can appear as a small
  secondary indicator, be queued, or be omitted.
- Critical events may become visible but should not steal keyboard focus
  without a genuine system requirement.
- Secure prompts use the real system service and modal semantics. Island is
  presentation, not a new security boundary.
- A semantic event is identified by a stable changing event ID. Routine value
  updates do not continuously retrigger event presentation.
- Hover can hold a transient so it can be read or clicked.
- On completion, restore the previous user state rather than blindly returning
  to the clock.
- Duplicate notification presentation should be avoided. Island must consume
  or coordinate with Omarchy's notification service, not become a second
  notification daemon.

## Multi-monitor policy

Each Omarchy bar owns a local Island widget, so Rest and pointer-hover Peek are
available on every connected monitor. Semantic provider state is shared rather
than duplicated, and actions plus retained Shelf/Focus/Controls surfaces resolve
on the focused monitor.

Working details to test:

- Connecting or disconnecting a monitor should follow the stock bar lifecycle
  without Island-specific placement configuration.
- A user-open panel remains on the monitor where it was opened until it closes.
- A secure system request appears on the currently relevant/focused monitor.
- Focus changes during a transient should not teleport it repeatedly.
- Keyboard invocation targets the focused monitor.
- Hover remains local to the Island under the pointer.

Generic OSD now latches the focused monitor for the life of an update
sequence. Passive pointer Peek yields and restores; keyboard/retained surfaces
and provider events keep ownership while the companion provides immediate
stock-style fallback feedback. **Delivered.**

## Capability inventory and initial treatment

| Capability | Rest/peek role | Initial activation | Enhanced future |
|---|---|---|---|
| Omarchy menu | Navigation | Rest click or menu icon opens launcher/menu | Unified search and command surface |
| Workspaces | Peek navigation | Reuse existing one-click selection | Island-native animated workspace strip |
| Indicators | Peek/conditional rest | Preserve current actions | Semantic DND, reminder, night-light, stay-awake, recording states |
| Keyboard layout | Peek | Reuse current indicator/action | Contextual input-source morph |
| Clock/calendar | Rest | Clock click or explicit target opens existing calendar | Island-native calendar/timezone view |
| Weather | Peek | Existing forecast panel | Compact weather event and rich forecast morph |
| System update | Conditional/event | Existing update action | Progress, completion, and failure activity |
| System tray | Peek drawer | Preserve StatusNotifier interactions | Island-aware tray grouping and menus |
| Tailscale | Peek/status | Existing panel and actions | Semantic connection activity |
| Bluetooth | Peek/status | Existing Bluetooth panel | First-class adapter or plugin-native morph |
| Network | Peek/status | Existing network panel | First-class adapter with scan/connect state |
| Audio | Peek/transient | Island-native volume transient, scroll, mute/slider Focus, and stock full-mixer handoff | Decide whether devices and per-app mixing should become native |
| Display | Peek/transient | Existing display panel | First-class brightness OSD and display morph |
| Power/battery | Peek/conditional event | Existing power panel | Charging, battery, and power-profile morph |
| Media | Conditional rest/activity | Existing MPRIS actions/panel | Rich track, progress, and playback morph |
| Notifications | Transient/event | Coordinate with existing service | Island-native event/history presentation |
| Reminders/timers | Event/activity | Existing reminder action | Semantic countdown/completion presentation |
| Screen recording | Conditional rest/activity | Existing recording controls | Persistent recording status and stop action |
| Polkit | Secure modal | Real existing authentication backend | Theme-native Island presentation with unchanged authority |
| Theme switcher | Modal tool | Existing theme command/surface | Island-native preview morph |
| Power actions | Modal tool | Existing lock/logout/reboot/shutdown flow | Island-native confirmation surface |

## Known hard parts

- System tray applications bring their own menus and assumptions.
- Several stock widgets own popup windows, anchors, timers, IPC handlers, and
  per-monitor instances in one component.
- Duplicating a stock widget while the stock bar is live can create conflicting
  IPC ownership or duplicate background work.
- Opening a proxy target during overlay development may anchor the popup to the
  original bar icon.
- True in-place presentation may require extracting reusable content from a
  popup without forking packaged code.
- Workspaces must remain immediate and reliable even while Island animates.
- Notification and OSD integration must avoid duplicate presentation.
- Polkit and destructive power actions need real modal and confirmation
  semantics, not decorative plugin actions.
- Theme and font changes must update live without restarting the desktop.
- Long labels, narrow monitors, scale factors, and reduced motion need explicit
  testing.
- Third-party QML runs inside the shared trusted shell process; Island metadata
  and validation do not create a sandbox.

## Configuration ideas

Potential user settings, not necessarily first-step UI:

- enabled/disabled;
- overlay versus replacement mode;
- hover and collapse delay;
- rest content policy;
- hover item order and visibility;
- grouped versus full hover layout;
- default rest click target;
- target-specific scroll behavior;
- monitor policy;
- motion duration, spring strength, and reduced motion;
- transient duration and event priority permissions;
- notification duplication policy;
- plugin-native custom-QML permission;
- per-plugin integration choice: native, Island adapter, standard, hidden;
- companion-overlay policy and optional future explicit replacement bar;
- theme inheritance and optional surface opacity;
- diagnostics and immediate stock-bar fallback.

## Suggested delivery sequence

This sequence is deliberately smaller than the full brainstorm.

### Phase 0: contracts and harness

- Define the host state machine and event priority.
- Define the standard target/handoff abstraction.
- Define a parity-ledger format for widgets.
- Build disposable visual/state tests before touching the live bar.

### Phase 1: safe overlay skeleton

- Top-center clock-only rest state.
- Hover expansion and collapse behavior.
- Launcher on rest click.
- Focused-monitor placement.
- A small set of proxy targets such as Bluetooth, network, and audio.
- Stock bar unchanged throughout.

### Phase 2: supported parity

- Cover the selected built-in adapter inventory.
- Preserve primary clicks, secondary actions, scroll, tooltips, and keyboard
  access where the standard integration can do so safely.
- Record gaps in the parity ledger rather than hiding them.
- The current executable ledger is [parity.md](parity.md). Unknown third-party
  widgets remain absent until they explicitly register Island support.

### Phase 3: high-value first-party morphs

- Volume transient, Peek scroll, and compact Audio Focus. **Delivered.**
- Brightness transient, Peek scroll, and compact Display Focus. **Delivered.**
- Media / now-playing activity. **Experimental reference provider delivered.**
- Notification coordination.
- Reminder/timer activity. **Delivered against Omarchy's existing scheduler.**
- Screen-recording activity with elapsed time at Rest, icon-sized Peek,
  validated stock click-to-stop/finalize routing, and a saved event. It does
  not introduce a custom Focus surface. **Delivered.**
- System-update availability companion with direct stock update activation and
  no custom presentation QML. **Delivered.**
- Optional generic OSD companion using Omarchy's clone/restore contract,
  focused-Island morphing, stock payload parity, and a stock-style fallback.
  The normal Island install leaves `omarchy.osd` untouched. **Delivered.**
- Connected morphs for the most-used system panels.

### Phase 4: public plugin integration

- Schema version 1 provider/action contract stabilized after Now Playing and
  Reminders reference integrations. **Delivered.**
- Ship examples, fallbacks, validation, diagnostics, and failure isolation.

### Phase 4.5: plugin-directory readiness

- Freeze a compatible manifest/protocol version only after first-party adapters prove it. **Schema version 1 frozen for the initial release.**
- Ship Now Playing, Reminders, Screen Recording, and System Update from the
  root plugin so the complete default Island requires one normal Omarchy
  installation. Keep the same provider contract for bundled and external
  implementations. **Delivered.**
- Keep the OSD replacement explicit and reversible through the optional
  companion helper; the root plugin never replaces `omarchy.osd`. **Delivered.**
- Test clean install, update, disable, rollback, and failure recovery without checkout symlinks. **Automated root-package and bundled-provider coverage delivered; clean Git lifecycle remains a release check.**
- Add release metadata, license, changelog, screenshots, compatibility matrix, support policy, and trust disclosure for custom QML. **Metadata, license, changelog, compatibility and trust documentation delivered; public preview remains optional.**
- Verify representative themes, scales, monitor layouts, missing stock widgets, third-party plugins, and older supported Omarchy releases.
- Prepare the repository and submission materials for the Omarchy plugin directory/site; publication remains a separate explicit decision.

## Parity ledger template

Every widget or surface should answer:

1. What is visible at rest, peek, and during an event?
2. What do left, middle, right, and scroll currently do?
3. What keyboard path exists?
4. Where does state live: widget, singleton service, system API, or command?
5. Can the existing surface be summoned without a live stock widget?
6. Can it anchor to Island without modification?
7. Is the item a built-in adapter or an explicit plugin registration?
8. Is an Island-provided adapter justified?
9. Does the plugin provide native Island integration?
10. What happens on multiple monitors, disable, reload, or failure?
11. Does it perform a privileged or destructive action?
12. How is accessibility and reduced motion preserved?

## Delivered projection model and next questions

The first live overlay clarified four requirements:

1. The rest surface should occupy exactly the active bar height, not a taller
   floating control.
2. The morph must feel immediate and decisive rather than springy or drawn out.
3. The Island represents supported built-ins and explicit plugin integrations,
   not the complete configured bar.
4. Size, motion, content order, monitor policy, and visual style need a stable
   user configuration contract.

The current implementation uses TOML-backed geometry, motion, layout and style;
known first-party adapters; and manifest-discovered plugin quick access and
activities. Panel-capable built-ins still use stock handoff.

### Delivered disclosure levels

- **Rest:** one intentionally chosen status, initially the clock.
- **Peek:** configured built-in adapters plus registered plugin entries.
- **Shelf:** a larger Island-owned view for tray programs, workspaces, and
  indicators.
- **Focus:** the selected provider activity's full surface, using optional
  plugin QML or the host's declarative fallback.
- **Controls:** a retained labeled view of the complete projection and an
  explicit exhaustive target; retained horizontal Peek is the default keyboard
  entry.

This avoids making hover produce an impossibly wide one-line replica of the
bar. Peek answers "what can I open?"; Shelf answers "what is in this group?";
Focus answers "what can I do here?"

### Remaining adapter opportunities after the delivered shelves

Tray, workspaces, indicators, keyboard layout, system update, audio volume, and display brightness now have the
first delivered adapters. The next adapter work is deeper fidelity rather than
basic reachability:

1. **Workspace urgency and scroll:** add urgent state and deliberate wheel
   navigation without changing the current direct-selection contract.
2. **Tray management and overflow:** expose pin/hide management and define
   behavior when the application count exceeds the finite Controls height.
3. **Richer indicator state:** carry reminder counts, dictation phases, and
   recording detail beyond the current active/inactive labels.
4. **Island-anchored stock adapters:** extend the delivered audio/display pattern to
   network and power, then decide whether audio's per-device and
   per-application mixer should remain a stock handoff or become fully native.

### Media / now-playing design gate

Now Playing is the first reference activity provider for the public integration
model. It runs through the same manifest discovery, lifecycle, semantic
publication, typed actions, fallback, monitor ownership, and optional
custom-presentation path available to third-party plugins. With that path now
working in daily use, schema version 1 is the stable baseline; the example
remains small enough for a plugin author or coding agent to copy without
depending on Island internals.

Volume and brightness remain first-party adapters for now, but their compact
transients and Focus controls are useful follow-on conformance cases. Once the
Now Playing provider establishes the contract, evaluate expressing these
built-ins through the same semantic host boundary without weakening their
stock-panel fallback.

The media adapter design considered:

- whether the compact motion should be a real waveform/level signal, an
  animated progress treatment, or a static progress visualization;
- what source provides trustworthy playback position and audio-level data;
- whether motion stops when paused and disappears when nothing is playing;
- which controls belong in Peek, the transient, and Media Focus;
- how title/artwork overflow, multiple players, privacy, reduced motion, and
  battery cost behave;
- whether the complete stock media panel remains the explicit fallback.

The delivered experiment ultimately chooses a static music note for the compact
state. MPRIS still supplies metadata, transport capabilities, playback state,
artwork, and track progress. Rest and Peek use a static note—full strength while
playing and dimmed when paused—inside a halo that shows real track progress.
Omarchy's optical glyph alignment keeps the note on the same visual rail as the
stock bar icons. The halo advances semantically but has no looping animation;
artwork remains contextual content in the expanded view. A future PipeWire level
source could add a genuinely audio-reactive presentation without changing the
semantic provider contract, but decorative audio motion is not part of the
default.

The live inspector should keep listing every configured but unprojected widget.
That list is the parity backlog and prevents the product from silently claiming
complete bar coverage.

## Open questions

- Does full hover inventory feel useful or too wide on the primary monitor?
- Should clicking expanded empty space open control center, or should control
  center always have an explicit target?
- How should the launcher relate to the existing Omarchy menu: replace its
  visual surface, wrap it, or route directly to it?
- Should a connected morph visually merge with an existing popup, or is a
  consistent anchored transition enough?
- Which first-party adapters provide the most value after volume/brightness?
- Should native plugin integration override an Island-provided adapter by
  default, or require user permission per plugin?
- What is the ideal hover/collapse delay after real daily use?
- Should volume, brightness, and provider transients appear on every Island or
  only the focused monitor's instance?
- How should tray overflow work inside a finite-width pill?
- Which notifications are allowed to appear in Island, and which remain stock
  toasts only?
- What minimum parity and recovery evidence is required before offering live
  replacement mode?

## Non-goals for the first step

- Removing or hiding the stock Omarchy bar.
- Editing packaged files under `/usr/share/omarchy`.
- Rebuilding every stock system panel.
- Adding independent provider state or configuration per monitor.
- Solving every notification, tray, secure-modal, and third-party-plugin edge
  case in the initial overlay.
- Treating plugin validation as a security sandbox.
