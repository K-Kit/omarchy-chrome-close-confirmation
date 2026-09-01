# Chrome Close Confirmation Design System

## 1. Atmosphere & Identity

The confirmation must feel like a native Omarchy safety checkpoint: quiet,
immediate, and unmistakably destructive without becoming alarming. Its
signature is a single focused card over the shell's themed scrim, with
**Keep Open** selected whenever the dialog appears.

## 2. Color

This plugin owns no color values. Every surface and state uses Omarchy Shell
tokens:

| Role | Omarchy token |
| --- | --- |
| Scrim | `Color.menu.scrim` |
| Card | `Color.menu.background` |
| Primary and secondary text | `Color.menu.text` |
| Card border | `Color.menu.border` |
| Destructive action | `Color.urgent` |
| Safe action and focus | `Color.accent` |

No raw color literals are permitted in `Plugin.qml`.

## 3. Typography

The overlay uses `Style.font.menuFamily` throughout. Heading, body, and
secondary copy use the corresponding `Style.font` scale. Window titles are
plain text, limited to two lines, wrapped, and elided.

## 4. Spacing & Layout

Spacing, padding, gaps, radius, and maximum card width derive from
`Style.spacing`, `Style.space()`, `Style.gapsOut`, and `Style.cornerRadius`.
The card is centered in a fullscreen `PanelWindow` and must remain within the
available monitor bounds at every size.

## 5. Components

### Confirmation Overlay

- **Structure:** fullscreen layer-shell window, scrim, bordered card, heading,
  window title, consequence copy, and two actions.
- **Variants:** one Chrome-window confirmation.
- **States:** closed, open with Keep Open selected, open with Close selected,
  and response in flight.
- **Accessibility:** exclusive keyboard focus; Escape and scrim click keep the
  window open; Left, Right, Tab, and Backtab change selection; Enter and Space
  activate it.
- **Motion:** only the host button primitive's theme-controlled state
  transition; no decorative motion.
- **Layout:** centered stack with a right-aligned action row.

### Omarchy Button

Use the shared `qs.Ui.Button` primitive for both actions. Keyboard selection
is mirrored through `hasCursor`; pointer hover updates the same selection
model. The destructive action uses `Color.urgent`.

## 6. Motion & Interaction

The overlay appears and disappears without custom animation so the intercepted
window-close command receives an immediate response surface. Existing Omarchy
button transitions provide hover, focus, and selected-state feedback.
Repeated input may produce only one response for a request.

## 7. Depth & Surface

Use Omarchy's mixed surface strategy: `BorderSurface` with
`Border.surfaceSpec()` over `Color.menu.scrim`. The plugin adds no shadows,
gradients, or custom elevation values.

## 8. Accessibility Constraints & Accepted Debt

### Constraints

- The safe action is selected by default.
- Every cancellation path returns `keep-open`.
- All untrusted window-title content renders with `Text.PlainText`.
- Focus is acquired after the layer-shell surface opens.
- Pointer and keyboard paths expose identical decisions.
- Theme and font-scale changes propagate through Omarchy tokens.

### Accepted Debt

None.
