# Stock Bar Parity Ledger

Pointer and keyboard Peek use the same Island-owned proxy controls. Stock
behavior remains authoritative, and proxies delegate to public actions, stock
panels, or feature-detected compatibility adapters. That routing remains the
same at the bar's top, bottom, left, or right edge. This ledger
tracks where that routing preserves parity, adds a richer retained morph, or
still needs work.

| Stock item | Primary | Secondary / middle | Scroll | Island status |
|---|---|---|---|---|
| Menu | Open launcher | Right: terminal | — | Preserved |
| Workspaces | Open Island workspace shelf, then focus workspace | — | — | Enhanced |
| Clock | Open stock calendar, including without a visible stock clock | Right: cycle clock format; middle: timezone menu | — | Island-anchored stock adapter |
| Tray | Activate or open item menu | Secondary activation | Item-specific | Enhanced |
| Status indicators | Open Island status shelf, then invoke state action | — | — | Island-anchored stock adapter |
| Keyboard layout | Cycle layout when multiple layouts are configured | — | — | Island-anchored stock adapter |
| Tailscale | Open stock panel | Right: toggle service; middle: refresh | — | Preserved |
| Bluetooth | Open stock panel | Right: toggle radio | — | Preserved |
| Network | Open stock panel | — | — | Preserved |
| Audio | Open Island Audio Focus | Right: mute; middle: full stock mixer | Volume | Enhanced |
| Display | Open Island Display Focus when brightness is supported; otherwise stock panel | Full stock display panel from Focus | Brightness | Enhanced |
| Power | Open stock panel | Right: toggle percentage | — | Preserved |
| Weather | Open stock panel | Right: full notification; middle: refresh | — | Preserved when projected |
| Media / now playing | Open Island Media Focus; previous, play/pause, and next inside Focus | — | — | Bundled provider |
| Reminders / timers | Next deadline at Rest; all outstanding reminders and New/Show/Clear actions in Focus | — | — | Bundled provider |
| Screen recording | Real elapsed time at Rest; click the icon to run Omarchy's stock Stop/finalize action; saved event after Island stop | — | — | Bundled provider with bounded stop |
| System update | Update-available activity; click runs Omarchy's stock floating-terminal updater | — | — | Bundled declarative provider; stock proxy remains opt-in |
| On-screen display | Optional companion routes the stock generic progress/message contract into the focused Island | Explicit close and duration `0` preserved | — | Optional reversible `omarchy.osd` clone with stock-style fallback |

“Preserved” means the proxy routes to the equivalent stock action or panel.
“Enhanced” keeps the stock component and panel as the source of truth while
adding an Island-owned view. Third-party plugins appear only when they declare
Island quick access or publish an Island activity.

This file describes the currently inspected Omarchy contracts. The runtime
feature-detects enhanced adapters, so an incompatible widget falls back to its
stock surface rather than leaving a dead control.
