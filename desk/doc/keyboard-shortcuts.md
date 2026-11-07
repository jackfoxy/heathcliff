# Keyboard shortcuts

## Heathcliff

| Keys | Action |
| --- | --- |
| F1 | Open Help |
| F2 | Open Settings |
| F5 | Reload the desk list and file trees |
| Ctrl+S | Save the active file |
| Ctrl+Shift+S | Save the active file as a new file |
| Alt+C | Copy the active file |
| Delete, with a file row focused | Delete that file, after confirming |
| Alt+Enter, Shift+F10, or the context-menu key | Open the focused item's actions |
| Up / Down in a desk's revision box | Browse newer / older revisions |
| Escape | Close a dialog or menu; leave fullscreen |

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

These are the default editor bindings. **Settings → Keybindings** selects
the default or Vim keymap.

| Windows/Linux | Mac | Action |
| --- | --- | --- |
| Ctrl+A | Command+A | Select all |
| Ctrl+Z | Command+Z | Undo |
| Ctrl+Shift+Z / Ctrl+Y | Command+Shift+Z / Command+Y | Redo |
| Ctrl+F | Command+F | Find |
| Ctrl+H | Command+Option+F | Replace |
| Ctrl+D | Command+D | Remove line |
| Alt+Up / Alt+Down | Option+Up / Option+Down | Move lines up / down |
| Tab / Shift+Tab | Tab / Shift+Tab | Indent / outdent |
| Ctrl+/ | Command+/ | Toggle comment |
| Ctrl+L | Command+L | Go to line |
| Ctrl+, | Command+, | Show the settings menu, which lists every command |

F1 opens Help rather than the command palette; the palette's commands are
listed in Ace's settings menu, above.
