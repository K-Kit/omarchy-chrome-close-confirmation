# Chrome Close Confirmation for Omarchy

Add a native Omarchy Shell confirmation overlay before `SUPER + W` closes
Google Chrome on [Omarchy](https://omarchy.org/). Every other application
keeps the normal, instant close behavior.

## Motivation

I built this after switching from macOS to Omarchy. My muscle memory kept
treating `SUPER + W` like `Command + W`, so I would accidentally close an
entire Chrome window when I only meant to close a tab. This confirmation adds
one deliberate checkpoint before a whole window—and all of its tabs—disappears.

> [!NOTE]
> This is a hybrid Omarchy plugin. The shell plugin renders the confirmation
> overlay, while a small Hyprland helper intercepts the close-window binding.
> Both pieces are required because shell overlays cannot intercept compositor
> keybindings by themselves.

## What it does

- Detects the currently focused window through `hyprctl`.
- Shows a theme-aware Omarchy Shell overlay for Chrome and Chromium windows.
- Uses **Keep Open** as the safe default.
- Falls back to Zenity if the running shell cannot serve the overlay.
- Closes non-Chrome windows immediately.
- Preserves your existing `bindings.lua` and creates timestamped backups.
- Installs entirely under your home directory; no `sudo` required.

## Requirements

- Omarchy with its Lua-based Hyprland configuration
- Omarchy Shell with third-party plugin support
- `hyprctl`
- `jq`
- `zenity` for the safe fallback dialog

Install missing fallback dependencies with:

```bash
omarchy pkg add jq zenity
```

## Install

```bash
omarchy plugin add \
  https://github.com/K-Kit/omarchy-chrome-close-confirmation.git \
  --enable
~/.config/omarchy/plugins/k-kit.chrome-close-confirmation/install.sh
```

The first command validates, installs, and enables the QML overlay through
Omarchy's plugin manager. The helper installer then:

1. Copies `bin/omarchy-close-window` to `~/.local/bin/`.
2. Adds a clearly marked override to `~/.config/hypr/bindings.lua`.
3. Reloads Hyprland and checks `hyprctl configerrors`.
4. Restores the previous configuration automatically if validation fails.

Re-running `./install.sh` updates the helper and replaces the existing managed
binding block without creating duplicates. It refuses to change Hyprland
unless the enabled overlay answers its readiness check.

## Usage

Press `SUPER + W` as usual.

| Focused window | Result |
| --- | --- |
| Google Chrome or Chromium | Choose **Close** or **Keep Open** |
| Any other application | Window closes immediately |

The confirmation includes the active window title so you can identify the
Chrome window before closing it.

## Uninstall

Run the installed plugin's uninstaller:

```bash
~/.config/omarchy/plugins/k-kit.chrome-close-confirmation/uninstall.sh
```

The uninstaller removes only this project's marked binding block and installed
helper, then removes the plugin through `omarchy plugin remove`. It leaves the
rest of your Hyprland configuration untouched and creates a timestamped backup
before editing.

## Troubleshooting

### `SUPER + W` does nothing

Confirm that the helper is executable and available:

```bash
command -v omarchy-close-window
test -x ~/.local/bin/omarchy-close-window && echo "executable"
```

Then validate Hyprland:

```bash
hyprctl reload
hyprctl configerrors
```

### The dialog does not appear

Confirm the plugin is enabled and responding:

```bash
omarchy plugin list --json |
  jq '.[] | select(.id == "k-kit.chrome-close-confirmation")'
omarchy-shell shell call k-kit.chrome-close-confirmation ping ''
```

The second command must print `ready`. If the shell overlay is unavailable,
the helper uses Zenity instead:

```bash
zenity --version
```

The helper matches any focused window class containing `chrome`,
case-insensitively. Inspect the focused window class with:

```bash
hyprctl activewindow -j | jq -r .class
```

### Restore the previous binding file

Installer and uninstaller backups sit beside the configuration file:

```text
~/.config/hypr/bindings.lua.bak.<timestamp>
```

Copy the desired backup over `bindings.lua`, then run:

```bash
hyprctl reload
hyprctl configerrors
```

## Test

Run the isolated lifecycle and behavior checks:

```bash
./tests/test.sh
```

The test uses a temporary configuration directory and command stubs. It does
not modify your live Hyprland configuration or close real windows.

## How it works

The managed binding replaces Omarchy's default close-window action:

```lua
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", "omarchy-close-window")
```

The helper reads the active window as JSON and checks the keep-loaded overlay
through shell IPC. For Chrome and Chromium it creates a private FIFO, sends its
path and the active window title to `Plugin.qml`, and waits for exactly one
`close` or `keep-open` response. The shell overlay uses Omarchy's shared
button, border, color, spacing, and focus primitives.

If the overlay is unavailable, the helper presents the existing safe-default
Zenity dialog. A confirmed response closes through Omarchy's current Lua
dispatcher API:

```bash
hyprctl dispatch "hl.dsp.window.close()"
```

## License

[MIT](LICENSE)
