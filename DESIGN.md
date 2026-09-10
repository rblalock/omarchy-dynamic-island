# Design System: Omarchy Island

Island is a standalone, draggable widget inside the normal Omarchy bar. The
stock bar remains intact; Island owns its Rest, proxy Peek, keyboard entry, and
retained detail surfaces.

## Overview

**Creative North Star: "A quiet aperture"**

Omarchy Island inherits the active Omarchy visual system and concentrates it
into one surface at the bar's configured edge. The interface is nearly absent
at Rest, becomes scannable at Peek, and gains only the space required for a
retained Shelf, Focus, or Controls task. The signature is the causal morph
between those states, not a separate brand layer.

The surface is an operate-mode shell extension: compact, theme-native, keyboard-capable, and explicit about fallback behavior. Provider artwork or custom QML may enrich the inside of the aperture, but the host continues to own its outer geometry, focus, close path, and failure state.

## Inventory contract

An item appears only when Island ships an enabled first-party adapter, an
enabled plugin declares `omarchyIsland.quickAccess`, or an enabled provider
publishes an activity. Ordinary bar registration is not Island registration.
Unknown widgets are omitted and diagnosed rather than receiving a guessed icon
or dead action.

## Colors

- **Surface:** `Color.popups.background`, unless `appearance.background` supplies a QML color string.
- **Primary text and glyphs:** `Color.popups.text`.
- **Accent and selected state:** `Color.accent` through Omarchy's shared state helpers.
- **Urgent activity:** `Color.urgent` for critical attention.
- **Border:** absent at Rest; Peek, compact transients, and retained surfaces fade in `Color.popups.border` unless `appearance.border` overrides it. Explicit `outline` style remains outlined at Rest.
- **Secondary text:** popup text with reduced alpha; never introduce a separate fixed neutral palette.

The `outline` style uses a slightly translucent popup surface and a persistent
two-pixel Rest border. `system`, `pill`, and `soft-square` use the normal popup
surface with no Rest border and a one-pixel boundary that fades in whenever
Island opens, including a compact transient.

## Typography

All text inherits `Style.font.family`. The clock and ordinary labels use `Style.font.bodySmall`; primary activity titles can rise to `Style.font.title`. Icons use the active Omarchy icon sizes and font unless a projected item supplies a specific glyph family.

Keep labels short enough to scan in a compact shell surface. Shelf labels and descriptions elide rather than widening cards without bound; activity subtitles wrap within Focus.

## Layout

The Island is an ordinary widget in every stock-bar surface. It inherits each
bar's placement and height and owns Rest, Peek, activities, and transient
morphs there. Actions and a subordinate retained-detail window resolve on the
Hyprland-focused monitor. That window exists only for Detail content and
invisible Wayland keyboard capture; it never renders another Rest clock or Peek
inventory.

Horizontal-bar Rest and Peek use the active bar height and content-derived
width. On a vertical bar, square Rest remains in the bar while the same
horizontal Peek or transient grows inward from that anchor in Island's retained
overlay; it never creates a second logical Island. Retained views share a
configurable shelf width, capped to the screen with 12
theme-scaled pixels of clearance per side. Shelf height derives from the active
collection plus retained chrome, treats an explicit height as a minimum, and
scrolls only when screen height becomes the cap. Focus and Controls retain
separate configured heights.

The bar-hosted Peek renders lightweight controls for configured first-party
adapters, registered plugin quick access, and current provider activity.
Pointer hover and keyboard entry operate that same inventory. Ordinary stock
widgets remain independently placeable in the normal bar.

## Elevation & Depth

The Island uses the theme's popup surface and border rather than inventing a
shadow system. Depth comes from retained-window placement, tonal separation,
the boundary stroke, and the surface morph. Rest and Peek mask input to the
card; retained views extend the input mask for outside-click dismissal.

## Shapes

`system` is the default and uses Omarchy's live `Style.cornerRadius`, which mirrors Hyprland `decoration:rounding`. `pill` uses a true capsule at Rest and Peek. `soft-square` uses a nine-unit theme-scaled radius in compact states. `outline` keeps system geometry while strengthening the border. A numeric `appearance.corner_radius` explicitly overrides inherited geometry in pixels.

Buttons inside shelves inherit that same effective radius. Persistent
current/enabled state uses selected fill. Hover uses tonal fill without a
stroke; keyboard focus adds the stronger theme focus fill and a short accent
chin inset along the compact surface's bottom edge. The chin has fixed geometry
and changes only opacity, so focus never moves content or neighboring controls.
Glyph-backed controls render through Omarchy's `OpticalGlyph` so their painted
bounds, rather than only their font boxes, are visually centered.

## Components

### Rest

- A host-owned compact clock by default; `activity` and `auto` may show the leading activity.
- Clicking the clock delegates to the existing Omarchy calendar panel.
- Provider minimal or event QML can render inside the host; declarative glyph and title remain the fallback.

### Peek

- Appears immediately on pointer entry and collapses after the configured delay.
- Keyboard invocation retains this same horizontal surface instead of changing
  to a separate layout. A vertical bar renders it in the retained overlay,
  attached to Rest and expanding inward. Arrows and `h/j/k/l` move the fixed
  focus chin; pointer hover can take over selection; activation morphs into the
  target surface or delegates to its stock panel; Escape closes.
- Renders compact proxy controls and routes pointer variants, scrolling, keyboard activation, and panel handoff through the shell or a compatibility adapter.
- Does not instantiate arbitrary bar widgets. Clock, status indicators, and
  keyboard layout have explicit hidden compatibility bridges when their visible
  stock widgets are absent because Omarchy exposes no independent service API
  for those behaviors.
- Provider compact or event QML may temporarily replace Rest; load failure returns to the declarative host presentation.
- Opening a native stock panel contracts Peek to the selected native anchor
  with an inset accent chin; the full inventory does not remain open above it.

### Shelf

- Retained workspaces, tray, and status collections use compact, direct controls.
- Retained controls use spatial keyboard navigation: arrows and `h/j/k/l` choose the nearest control in that direction, pointer hover can take over focus, and `Home`/`End` move to the first or last control. Grids follow their visible rows and columns rather than flattening into an arbitrary sequence.
- Workspaces show the complete configured range, preserve each number while indicating the focused and occupied state, and label workspace 10 as `0`. Tray preserves primary, secondary, menu, and scroll interactions. Status follows the stock indicator order/subset and shows labeled on/off state.

### Focus

- Uses a provider's expanded QML when it loads successfully.
- Otherwise shows the host-owned title, subtitle, attention glyph, progress, and labeled action buttons.
- Provider action buttons route through the host to the provider rather than executing arbitrary host behavior from metadata.
- Audio Focus is a host-owned adapter: it shows the live output, volume slider, mute action, and an honest handoff to the complete stock mixer.
- In Audio Focus, Left/Right and `h/l` adjust the focused volume slider; `j/k` moves between the slider and actions.
- Display Focus is a host-owned adapter when the stock monitor widget reports brightness support. It shows the focused display, brightness slider, and an honest handoff to the complete stock display panel. Without supported brightness it delegates immediately.
- In Display Focus, Left/Right and `h/l` adjust the focused brightness slider; `j/k` moves to the stock-panel handoff.

### Transient

- A routine output-volume or brightness change can temporarily replace Rest with one horizontal readout at bar height.
- The transient renders inside a horizontal bar widget or grows inward from a
  vertical Rest anchor in the retained overlay. Hover Peek and every retained
  user-open surface outrank it; a provider event also suppresses it.
- Clicking a transient opens its matching Focus view. Reduced motion keeps the state change and removes the spatial morph.

### Controls

- Presents the complete supported inventory as labeled tiles and describes whether each item opens a shelf, focus view, quick-access target, or stock panel.
- Remains an explicit exhaustive/power-user view rather than the default keyboard destination.

### Retained frame

- Shelf, Focus, and Controls omit redundant title and close chrome; the contents identify the surface.
- Retained views request `WlrKeyboardFocus.Exclusive`, support spatial arrows and `h/j/k/l`, advance through the focus chain with `Tab`, activate with `Enter` or `Space`, and close with `Escape` or outside click.

### Motion

- Width and height expand in 260 ms and collapse in 180 ms with cubic deceleration. This preserves Omarchy's quick-arrival character without reusing its highly front-loaded window curve for a much larger geometry change.
- Destination content is measured at its final width before the shell morphs, so tile wrapping and the height target remain stable throughout the transition. Content and the outer Peek or retained boundary fade over 150 ms without scaling text or changing geometry; control fills and the fixed-geometry keyboard-focus chin fade in about 90 ms without changing layout.
- `motion.reduced`, `motion.enabled = false`, and `OMARCHY_ISLAND_REDUCED_MOTION=1` remove spatial motion without removing content or actions.

## Do's and Don'ts

### Do

- **Do** inherit live Omarchy color, type, spacing, and glyph language.
- **Do** keep Rest intentionally sparse and let state changes explain added density.
- **Do** preserve a declarative fallback for every optional provider presentation.
- **Do** keep stock-panel delegation and Island-owned adapters visually honest about where behavior lives.
- **Do** provide the same visible state language for hover, press, selection, and keyboard focus.

### Don't

- **Don't** replace the stock bar or relocate its widgets.
- **Don't** imply that a delegated panel is Island-native while it still opens at a stock anchor.
- **Don't** let plugin custom QML own the retained window, global focus policy, or close contract.
- **Don't** render unresolvable plugins as inert controls; report them through inspection.
- **Don't** use looping or decorative idle motion.

## Current boundaries

- A visual editor for enabling and ordering built-in adapters is not implemented.
- Delegated launcher, system, and weather panels remain at stock anchors. Audio
  and Display have host-owned Focus adapters, while their complete stock panels
  remain at stock anchors.
- Custom provider QML is trusted in-process plugin code, not isolated content.
- Schema version 1 is the public provider contract. Future work is tracked in
  [ROADMAP.md](ROADMAP.md).
