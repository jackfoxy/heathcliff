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
its data directory: the row `%obelisk` holds what is inside `/data` on
`%obelisk`. When `/data` holds nothing but a folder named for the desk,
as an app's own file root usually does (`/data/obelisk`), the row shows
that folder's contents directly. A desk without `/data` says so. Browsing
never creates a `/data` directory.

Desks are sorted by their app name, ignoring case. The name comes from the
desk's `desk.docket-0` title; a desk without one shows its desk name. When
the two differ, the desk name follows in grey, as `%desk`.

A file whose stored data has been tombstoned at the revision shown is
listed as `name.mark (tombstoned)`; it cannot be opened, downloaded or
deleted again, though Attributes… still works.

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
from it are labelled `name.mark version N`. Text files can be edited. Stepping up
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

Saving a historical file warns that it will create a new current version.
Confirming saves to the same file at `now`; the historical version stays
unchanged, and the source tab switches to the current file. Cancel leaves
your edits unsaved. Concurrent changes to the current file still trigger
the normal overwrite warning. Identical content does not create a revision.

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

- Markdown renders on the ship with the Hoon Markdown library, including
  tables, task lists, and fenced code. Scripts and unsafe HTML are removed.
  Previews accept up to 64 KiB; larger documents show source and a message.
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
- **Attributes…** for file, desk, or folder information.
- **Permissions…** for read and write rules and crews.
- **Upload…** into a desk or folder at now.
- **Delete** a file's version at an older revision (see below). Disabled
  at now: Heathcliff does not delete current files.
- **Now** and **Revision…**: browse the item's desk at now, or at a
  revision you choose.

## File and path attributes, and permissions

**Attributes…** opens a closable tab in the reference pane for the chosen item:
its ship, app and
desk, revision, path, kind and mark; for a file its size, type, and whether
its data is still stored; for a folder how many items it holds.

File tabs use `name.mark` at the current revision and `name.mark version N`
for a historical revision. Opening the same item's attributes again selects
its existing reference tab. Different files and revisions can stay open
side by side; the source and result panes remain usable.
Double-click a file's Attributes or Permissions tab to open that file in
the source and display panes at the tab's revision.

Audio, video, MIME, and image files append populated, read-only MediaInfo
attributes for the container and each track. These include format descriptions,
compression methods, stream sizes and file percentages, timing, audio and
color properties, and codec-specific metadata when available. Internal
bookkeeping and duplicate formatted representations are omitted. SVG
shows its decoded dimensions. These describe the committed file at the
selected revision. Unknown or unreadable formats show a message; ordinary
attributes remain available.

**Permissions…** opens a separate reference tab for the chosen item. It
shows the **read** and **write** rules in force, in
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
  older revision the permissions tab shows today's rules, says so, and does not let
  you change them.
- **Write rules are not enforced.** This kernel stores and inherits write
  rules but never checks them. Treat a write rule as a record, not as
  protection.

## Deleting from history

Clay's history cannot be rewritten: an old revision always lists its
files. What can go is the stored content of a version. **Delete**, on a
file opened at an older revision, tombstones that content after you
confirm. Heathcliff then reloads the listing.

- Clay stores identical content once, so every revision and path holding
  exactly that content shows it as tombstoned afterwards.
- Clay refuses, and Heathcliff reports it, when any desk's current
  revision still uses that content.
- It cannot be undone.

Delete is disabled at now. To remove a current file, use the dojo.

## Uploading

Select a folder or desk at now and press **Upload…** in the toolbar, or use
**Upload…** in its item menu. Choose a file from your computer; cancelling
the chooser does nothing.

In **Settings → Apps uploads**, choose **Upload to /data/ in Apps**
(the default) or **Upload to / in Apps**. This preference is saved in this
browser. In Apps, the selected folder is relative to that prefix: selecting
the desk uploads to `/data/` or `/`, and selecting `/notes` uploads to
`/data/notes` or `/notes`. A selected path already under `/data/` keeps that
prefix once. Data view uploads stay in the selected Data directory.
Selecting a file uses its containing folder; with nothing selected, the
active file's folder is used.

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

**Download…**, immediately left of **Upload…** in the toolbar, saves the
active file at its selected revision. It is disabled for unsaved drafts.
The item's context menu also offers **Download**.

The download is the file's external form, its mark's own conversion to bytes:
most files come back exactly as stored, a `mime` file as its stored bytes,
and a `noun` file as its jam. Structured marks such as `bill` download as
the text their mark prints, not necessarily the bytes that were uploaded.

Downloads and previews are served so that no stored HTML, SVG or script can
run as part of Heathcliff.
