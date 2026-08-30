# Omarchy Island

## Product

Omarchy Island is a quiet, morphing interaction host that lives as one ordinary
widget in Omarchy's stock bar. It starts as a clock or current activity, reveals
supported controls on hover or keyboard entry, and gives Island-aware plugins a
focused quick-access or activity surface.

The stock bar and its widgets remain installed, visible, and independently
draggable. Island never adopts or mounts another bar widget.

## Inventory contract

An item appears in Island only when one of these is true:

1. Island ships a first-party adapter for it and it is enabled in `layout.peek`.
2. An enabled plugin declares `omarchyIsland.quickAccess`.
3. An enabled plugin publishes an activity through an `omarchyIslandProvider`.

Ordinary bar registration alone is not Island registration. Unknown bar widgets
are ignored rather than receiving a guessed icon or action.

## Delivered milestone

- **Rest:** clock by default, with configurable activity or automatic activity content.
- **Peek:** one pointer and keyboard inventory made from supported adapters and registered plugins.
- **Shelf:** retained Island-owned workspaces, tray, and status collections.
- **Focus:** audio, display, and provider activity surfaces with stock handoff where appropriate.
- **Plugin integration:** quick access, semantic activities, typed actions, optional rich QML, and declarative fallback.
- **Keyboard:** `SUPER+R`, arrows or `h/j/k/l`, `Tab`, `Enter`/`Space`, and `Escape`.
- **Placement and safety:** focused monitor only, no stock-bar replacement or layout mutation.
- **Configuration:** hot-reloaded TOML for appearance, motion, built-in inventory, adapters, and provider policy.

## Product principles

- **Explicit compatibility.** Support comes from a maintained adapter or an Island registration contract.
- **Quiet at rest.** Persistent information must earn its space.
- **Host-owned coherence.** Island owns geometry, focus, motion, arbitration, and fallback presentation.
- **Plugins own their domain.** Plugins publish semantic state and typed actions without owning shell windows.
- **No dead controls.** Unsupported widgets stay out of Island.
- **Stock behavior remains available.** Island does not remove or relocate ordinary bar widgets.

## Current boundaries

- Delegated stock panels still appear at their stock-widget anchors.
- Custom provider QML executes as trusted code inside the shared shell process.
- The implemented manifest contract needs a frozen public SDK and compatibility policy before marketplace publication.
- A visual inventory editor and a more general registered-widget contract remain future work.
