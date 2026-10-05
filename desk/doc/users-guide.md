# Heathcliff user guide

Heathcliff shows the Clay filesystem of your ship: every desk, every file,
and every revision. You can edit text files, preview the rest, download
and upload files, and manage read and write permissions.

Open it at `/heathcliff` on your ship. You must be logged in.

## The workbench

Three panes, left to right:

- **Explorer**: the Apps and Data views.
- **Source**: the open files, as tabs, with the editor.
- **Result**: a preview or decoded view of the active file.

Drag the dividers to resize. Settings (the gear) holds the theme, the
screen layout (columns or rows), and the editor keymap. Tabs, their
unsaved text, and which folders are open are remembered in this browser.

## Apps and Data

**Apps** lists every desk on the ship, system desks included, each with
its whole Clay tree. **Data** lists the same desks, by desk name, each as
its `/data` directory: the row `%obelisk/data/` holds what is inside
`/data` on `%obelisk`. A desk without one says so. Browsing never creates
a `/data` directory.

Desks are sorted by their app name, ignoring case. The name comes from the
desk's `desk.docket-0` title; a desk without one shows its desk name. When
the two differ, the desk name follows in grey, as `%desk`.

Folders come before files, both sorted by name. A file shows as
`name.mark`: Clay has no file extensions, so `/app/dojo/hoon` is the file
`dojo.hoon` in `app`.

Apps and Data remember their open folders and selections separately. A
file opened from either view is the same document: opening it again goes
to its existing tab.

### Older revisions

Each desk has a revision box beside its name. It starts at `now N`, the
live desk at its latest revision N. Step back with ▾ (or the Down arrow),
or type a revision number, to browse that desk as it was; files opened
from it are read-only snapshots, labelled with their revision. Stepping up
to N with ▴ (or the Up arrow) returns to `now N`. A revision number
belongs to its desk alone and is never applied to another.

Every item's menu also has **Now**, which returns its desk to the current
revision, and **Revision…**, which asks for a revision number. Both are
disabled on a desk with only one revision, and Now is disabled when the
desk is already at now. A revision the desk does not have is refused with
its valid range, and nothing changes.

## Editing

Text files open editable: txt, csv, tab, md, pem, hoon, css, js, html, svg,
xml, udon, umd, map and json. Four structured marks edit as the text their
mark prints and parses: bill, docket-0, kelvin and ship. Saving converts
the text through the desk's own mark, so the saved file may come back in
the mark's canonical form.

Save with the Save button or Ctrl/Cmd+S. A save is confirmed only after
Clay has committed it and the file reads back as expected. If the file was
changed elsewhere since you opened it, Heathcliff asks before overwriting.
Text a mark cannot hold, such as invalid JSON, is refused with an error.

Every other file opens read-only: images, audio, video, fonts, PDFs, atoms,
jams, nouns, mime files, hymn, urb, snip and txt-diff, and any mark
Heathcliff does not know. The source pane then shows a summary, a hex dump,
or a printed noun, and the result pane shows the preview. A file whose
stored data does not match what its mark name suggests (for example an old
`md` stored as a single cord) also opens read-only.

A new, empty tab is a draft. Saving it asks for a path typed as
`desk/now/folder/name.mark`, for example `base/now/notes/todo.txt`.

## The result pane

The result pane previews the active file. For text it shows the current
buffer, marked **unsaved buffer** when it differs from the saved file; for
binary files it shows the committed file.

- Markdown renders through urui's sanitized renderer.
- HTML renders in a sandboxed frame that runs no scripts.
- SVG shows as an image; its scripts never run.
- CSV and TSV show as tables (the first 500 rows).
- JSON shows as a collapsible tree; XML as a parsed tree, or its parse
  error.
- Hoon, CSS and JavaScript show as source. Nothing is run or applied.
- Images, audio and video use the browser's own players. Formats the
  browser cannot play say so and offer Download. MIDI has no native
  playback.
- Fonts show a specimen. PDFs open in the browser's viewer.
- hymn, urb and snip render, sandboxed, through their mark's HTML
  conversion. A mime file previews by its stored type.

## Item actions

Right-click any desk, folder or file, use its **…** button, or focus it and
press Shift+F10 or the context-menu key:

- **Open** a file.
- **Download** a file.
- **File attributes…** for a file, **Path attributes…** for a desk or
  folder.
- **Upload…** into a desk or folder at now.
- **Delete** a file at now. Heathcliff asks first.
- **Now** and **Revision…**: browse the item's desk at now, or at a
  revision you choose.

## File and path attributes, and permissions

**File attributes…** (on a file) or **Path attributes…** (on a desk or
folder) opens a dialog for the chosen item: its ship, app and
desk, revision, path, kind and mark; for a file its size, type, and whether
its data is still stored; for a folder how many items it holds.

The permissions part shows the **read** and **write** rules in force, in
plain words ("only 2 ships", "everyone except 1 crew"), and where each comes
from: set on this item, inherited from a parent, or Clay's default.

At now you can set a rule here (whitelist or blacklist, with ships and
crews) or clear it so the item inherits from its parent. A rule naming a
crew that does not exist is refused, because Clay would ignore it.

**Explicit rules here and below** lists rules set on this item or under it.
Clay cannot list its rules, so Heathcliff checks every path that has files
under it, up to 512; it says when it stopped early, and a rule on a path
with no files cannot be found.

**Crews** are groups of ships, defined for the whole ship rather than one
desk. Create, edit or delete them here, and see how many rules name each.
Deleting a crew removes it from every rule that names it: a whitelist then
admits fewer ships, but a **blacklist then admits more**, because the ships
it excluded are no longer excluded. Crews edited elsewhere (the dojo) show
after **Reload crews from clay**.

Two limits come from Clay itself:

- **Rules are current only.** Clay keeps no history of permissions. On an
  older revision the dialog shows today's rules, says so, and does not let
  you change them.
- **Write rules are not enforced.** This kernel stores and inherits write
  rules but never checks them. Treat a write rule as a record, not as
  protection.

## Uploading

Select a folder or desk at now and press **Upload…** in the toolbar, or use
**Upload…** in its item menu. Choose a file from your computer; cancelling
the chooser does nothing.

The file's extension becomes its mark: `photo.png` is stored as
`/folder/photo/png` with mark `png`. Before anything is written, Heathcliff
shows where the file will go and anything that needs a decision:

- **The file exists**: tick *Replace the existing file* to overwrite it.
- **The desk lacks the mark**: see below.
- **It cannot be stored**: for example a file over 8 MiB, a mark Heathcliff
  cannot convert uploads into (hymn, jam, noun, snip, txt-diff, urb), or a
  file ending in NUL bytes under a mark that would drop them.

The upload is committed in one step, together with any marks it needs, and
confirmed only once Clay reads it back intact. The file then opens in a tab.

### Marks Heathcliff copies into your desks

Clay only accepts a file into a desk that has the file's mark. If the
target desk lacks it, Heathcliff can copy the mark's source into the desk
in the same commit as the file, but only when you tick *Install these
marks*. The dialog lists each mark it would copy and where from.

- **Which marks**: the file's mark and the marks it builds on. Most marks
  build on `mime`; `hoon`, `udon` and `umd` build on `txt`; `bill`,
  `docket-0`, `hymn`, `kelvin`, `ship`, `snip`, `txt-diff` and `urb` build
  on `noun`.
- **Where from**: a mark that `%base` has is copied from `%base`. Only a
  mark `%base` lacks is copied from Heathcliff's own desk (its `mar/`
  directory). Heathcliff's copies of marks that `%base` also has are kept
  identical to `%base`.
- **Never replaced**: a mark the desk already has is never touched, even if
  it differs from `%base`'s.
- **What it means**: the target desk gains new files under `mar/`. They
  stay after the upload, are committed like any other file, and are
  included if that desk is later published or synced. Remove them by hand
  if you no longer want them; Clay will then refuse files that need them.

## Downloading

**Download** saves a file to your computer, from now or any revision. The
download is the file's external form, its mark's own conversion to bytes:
most files come back exactly as stored, a `mime` file as its stored bytes,
and a `noun` file as its jam. Structured marks such as `bill` download as
the text their mark prints, not necessarily the bytes that were uploaded.

Downloads and previews are served so that no stored HTML, SVG or script can
run as part of Heathcliff.
