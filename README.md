# Chrome Close Confirmation for Omarchy

Add a confirmation dialog before `SUPER + W` closes Google Chrome on
[Omarchy](https://omarchy.org/). Every other application keeps the normal,
instant close behavior.

## Motivation

I built this after switching from macOS to Omarchy. My muscle memory kept
treating `SUPER + W` like `Command + W`, so I would accidentally close an
entire Chrome window when I only meant to close a tab. This confirmation adds
one deliberate checkpoint before a whole window—and all of its tabs—disappears.

> [!NOTE]
> This is a user-level Hyprland customization, not an Omarchy Shell widget.
> Window closing is handled by Hyprland, so the repository installs a small
> helper and overrides Omarchy's existing close-window binding.

## What it does

- Detects the currently focused window through `hyprctl`.
- Shows a native Zenity confirmation for Chrome and Chromium window classes.
- Uses **Keep Open** as the safe default.
- Closes non-Chrome windows immediately.
- Preserves your existing `bindings.lua` and creates timestamped backups.
- Installs entirely under your home directory; no `sudo` required.

## Requirements

- Omarchy with its Lua-based Hyprland configuration
- `hyprctl`
- `jq`
- `zenity`

On Omarchy, install missing dependencies with:

```bash
omarchy pkg add jq zenity
```

## Install

```bash
git clone https://github.com/K-Kit/omarchy-chrome-close-confirmation.git
cd omarchy-chrome-close-confirmation
./install.sh
```

The installer:

1. Copies `bin/omarchy-close-window` to `~/.local/bin/`.
2. Adds a clearly marked override to `~/.config/hypr/bindings.lua`.
3. Reloads Hyprland and checks `hyprctl configerrors`.
4. Restores the previous configuration automatically if validation fails.

Re-running `./install.sh` updates the helper and replaces the existing managed
binding block without creating duplicates.

## Usage

Press `SUPER + W` as usual.

| Focused window | Result |
| --- | --- |
| Google Chrome or Chromium | Choose **Close** or **Keep Open** |
| Any other application | Window closes immediately |

The confirmation includes the active window title so you can identify the
Chrome window before closing it.

## Uninstall

From the cloned repository:

```bash
./uninstall.sh
```

The uninstaller removes only this project's marked binding block and installed
helper. It leaves the rest of your Hyprland configuration untouched and
creates a timestamped backup before editing.

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

Verify Zenity is installed:

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

The helper reads the active window as JSON, prompts only when its class matches
Chrome, and closes through Omarchy's current Lua dispatcher API:

```bash
hyprctl dispatch "hl.dsp.window.close()"
```

## License

[MIT](LICENSE)
