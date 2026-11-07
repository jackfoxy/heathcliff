# Keyboard shortcuts

## Heathcliff

<!-- generated: app-chords -->

| Key | Action | Where |
|:----|:-------|:------|
| F1 | Help (displaces Ace’s Open command palette) | Everywhere |
| F2 | Settings (displaces Ace’s Toggle fold widget) | Everywhere |
| F5 | Refresh the file tree | Outside the editor |
| Ctrl-S | Save the active file | Everywhere |
| Ctrl-Shift-S | Save the file as | Everywhere |
| Alt-C | Copy the file | Outside the editor |

<!-- /generated -->

With a file row focused in the explorer: **Enter** or **Space** opens the
file, **Delete** deletes it after confirming, and **Alt+Enter**,
**Shift+F10** or the context-menu key opens the row's actions. **Up** and
**Down** in a desk's revision box browse newer and older revisions, and
**Escape** closes a dialog or menu and leaves fullscreen.

F1 and F2 override Ace's command palette and fold-widget bindings, matching
the other apps on this shell. The palette's commands remain reachable through
**Ctrl+,**, Ace's own settings menu; folding keeps `Alt+F2`, `Alt+L`,
`Alt+Shift+L`, `Alt+0` and `Alt+Shift+0`.

**F5 reloads the trees here; in Obelisk the same key runs a query.** Heathcliff
has nothing to run, so the two meanings do not collide, but they are different
on purpose.

Alt+C rather than Ctrl+Shift+C for Copy, which Chromium keeps for its element
inspector. There is no Open chord: the explorer is how a file is opened. Copy
and the row keys apply outside the editor only, so Ctrl+C and its neighbours
keep their ordinary meaning while editing.

Saving an edited historical text file asks before creating a new current
version. Read-only files cannot be saved.

## Ace source editor

The source pane uses the vendored Ace editor. Its full default keymap is in
**[Ace editor keys](ace-keys.md)**, generated from the same manifest the
cross-app conflict gate reads. **Settings → Keybindings** selects the
default or the Vim keymap.

## Dialogs

Help and Settings navigate the same way in every app on this shell; see
**[Dialog keyboard contract](modal-keys.md)**.

## Policy

Why a chord is or is not available, and what it may displace:
**[Key policy](key-policy.md)**.
