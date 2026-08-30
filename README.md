# Omarchy Island

Omarchy Island is a morphing Quickshell widget that lives inside Omarchy's
existing bar. It keeps the stock bar intact, expands supported controls on
hover or from the keyboard, and presents ongoing desktop activity without
adding another shell process or panel system.

## Requirements

- Omarchy 4 with the Quattro shell plugin host
- A Nerd Font supplied by the active Omarchy theme

The initial release is tested on Omarchy 4.0.1. Its bundled activities reuse
Omarchy's existing media, reminder, screen-recording, and update facilities;
they do not install another scheduler, recorder, updater, or media service.

## Install

```bash
omarchy plugin add https://github.com/rblalock/omarchy-dynamic-island.git --enable
```

That single command installs and enables the complete default experience:

- Rest clock with calendar and clock-format actions
- Hover Peek with supported system controls
- Workspaces, tray, and status detail views
- Audio and display controls with transient feedback
- Now Playing with real playback progress
- Reminder countdowns backed by Omarchy reminders
- Screen-recording status and stock click-to-stop behavior
- System-update availability with the stock update launcher
- Third-party Island provider discovery and diagnostics

The widget starts in the center section and can be dragged or moved like any
other Omarchy bar widget. It appears on every monitor where Omarchy renders its
bar; retained actions target the focused monitor.

## Use

- Hover the Island to reveal Peek.
- Click a compact item to invoke its normal action or open its detail.
- Use the mouse wheel over audio or display to adjust it.
- Press arrows or `h/j/k/l` after keyboard entry to navigate.
- Press `Enter` or `Space` to activate and `Escape` to close.
- Click the clock to open the stock calendar; right-click it to cycle formats.

The recommended optional Hyprland binding is:

```lua
o.bind("SUPER + R", "Omarchy Island", "omarchy-shell omarchy-island keyboard")
```

Add it through your normal user Hyprland configuration. The plugin never edits
Hyprland or Omarchy configuration during installation.

## Configure

Island reads optional user overrides from:

```text
~/.config/omarchy/island.toml
```

The file is not required and is not created, overwritten, or removed by the
plugin. Configuration hot-reloads. See [Configuration](docs/configuration.md)
for appearance, motion, inventory, provider ordering, and adapter settings.

## Island-aware plugins

Enabled Omarchy plugins can explicitly register quick access, publish semantic
activities, and optionally provide trusted custom presentations through the
`omarchyIsland` manifest contract. Ordinary bar-widget registration does not
place a plugin inside Island.

The host owns outer geometry, animation, focus, monitor routing, dismissal,
arbitration, and declarative fallback. See the [Plugin API](docs/plugin-api.md)
and repository-owned [agent skill](.agents/skills/omarchy-island/SKILL.md).

## Optional OSD companion

The normal installation leaves Omarchy's stock OSD untouched. An explicit
companion can route stock OSD events through Island while retaining a
stock-style fallback:

```bash
~/.config/omarchy/plugins/rblalock.omarchy-island/scripts/osd-companion-enable
```

Disable it at any time to restore the stock presenter:

```bash
omarchy plugin disable rblalock.omarchy-island-osd
```

For agent-assisted setup, give the user's coding agent this prompt:

> Install the optional Omarchy Island OSD companion from the installed
> `rblalock.omarchy-island` plugin. Use its `scripts/osd-companion-enable`
> helper; do not edit `/usr/share/omarchy` or rewrite shell configuration.
> Verify that the companion is enabled, that Island remains available on the
> focused monitor, and that disabling the companion restores `omarchy.osd`.

See [OSD companion](docs/osd-companion.md) for behavior and recovery details.

## Inspect and troubleshoot

```bash
omarchy-shell omarchy-island inspect | jq
omarchy plugin list
omarchy restart shell
```

Provider-specific diagnostics are available at:

```bash
omarchy-shell omarchy-island inspect \
  | jq '.providerDiagnostics[] | {providerId, status, reason, error, activities}'
```

Island treats unavailable stock controls and provider failures as optional
capability loss. It does not remove the stock bar or prevent stock panels from
being used.

## Update, disable, and remove

```bash
omarchy plugin update rblalock.omarchy-island
omarchy plugin disable rblalock.omarchy-island
omarchy plugin enable rblalock.omarchy-island
omarchy plugin remove rblalock.omarchy-island
```

Disabling or removing Island leaves the stock bar and user-owned
`~/.config/omarchy/island.toml` unchanged. Disable the optional OSD companion
first if it is installed.

## Trust and security

Omarchy plugins run as unsandboxed code inside the long-lived
`omarchy-shell` process. Review plugin code before enabling it.

Island reads its bundled defaults and optional user TOML file. Its adapters and
activities invoke established Omarchy commands for reminders, recording, and
updates. Third-party provider QML is trusted code; users can disable custom QML
globally or per provider while retaining the declarative activity fallback.

Island requires no `sudo`, `pkexec`, package installation, remote build, or
background service of its own.

## Development

Start with [AGENTS.md](AGENTS.md), then run:

```bash
./scripts/check
./scripts/dev-sync
omarchy-shell omarchy-island inspect | jq
```

`dev-sync` installs a validated managed copy for local development. It is not
part of the public installation path.

## License

[MIT](LICENSE)
