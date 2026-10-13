# Heathcliff

A Clay filesystem explorer for Urbit: browse every desk and revision, edit
text, preview files, upload and download directory trees, and manage
permissions and crews.

Heathcliff works directly with the files on your ship. It is not a separate
storage service: saves and deletions are Clay commits, and historical views
show the revisions of the selected desk.

```hoon
|install ~dister-nomryg-nilref %heathcliff
```

## Browser workbench

Open the Heathcliff tile or visit `/heathcliff` through your ship's HTTP
interface. You must be logged in.

The interface has three resizable panes: an explorer, a tabbed source editor,
and a result preview. **Apps** exposes complete desk trees; **Data** focuses
on each desk's `/data` directory. Each desk has its own revision selector,
so current and historical files can stay open side by side.

- Edit text with the bundled Ace editor, including Hoon, Markdown, JSON,
  HTML, CSS, JavaScript, and shell scripts. New drafts can be saved through
  a browsable desk and folder requestor.
- Preview Markdown, tables, structured data, images, audio, video, fonts,
  and PDFs. Unknown or non-editable marks open as read-only summaries,
  hex dumps, or printed nouns.
- Inspect file, folder, and desk attributes in separate reference tabs.
  MediaInfo provides container and track metadata for supported media.
- Upload individual files or folders, preserving subfolder paths, and
  download files or complete partial trees at a selected revision.
- Set or clear read and write rules, inspect inheritance, and manage
  ship-wide crews.

Tabs, unsaved text, explorer state, layout, theme, and editor preferences are
remembered in the browser. Saving an older file writes a new current version
after confirmation; it never rewrites the historical revision. Concurrent
changes trigger an overwrite warning, and saves are verified by reading
the committed file back from Clay.

The page, CSS, and application JavaScript are generated from Hoon using the
vendored urui libraries. Ace and MediaInfo assets are served by Heathcliff
itself. There is no separate frontend build, glob, or runtime CDN dependency.
HTML previews are sandboxed, and stored scripts are not executed.

## Documentation

- [Users Guide](desk/doc/users-guide.md): browsing, editing, previews,
  permissions, and file-transfer workflows.
- [Reference](desk/doc/reference.md): toolbar buttons, context menus,
  dialogs, and settings.
- [Keyboard Shortcuts](desk/doc/keyboard-shortcuts.md): editor and
  workbench commands.
- [About Heathcliff and Ace](desk/doc/about.md): version and credits.

The same topics are available from **Help** in the workbench. If the ship
does not serve `/docs`, Help provides a short built-in guide instead.

## Install from source

The checked-in `desk/` contains the application, shared libraries, marks,
documentation, and browser assets. A sibling urui checkout is not needed
to install it. Kernel compatibility is declared in
[`desk/sys.kelvin`](desk/sys.kelvin).

On a development ship, create and mount a desk:

```hoon
|new-desk %heathcliff
|mount %heathcliff
```

Copy the **contents** of this repository's `desk/` directory into the
mounted `heathcliff/` directory, then commit and install from the dojo:

```hoon
|commit %heathcliff
|install our %heathcliff
```

Installation starts `%heathcliff`, as declared in
[`desk.bill`](desk/desk.bill). The tile's direct-site entry in
[`desk.docket-0`](desk/desk.docket-0) opens `/heathcliff`.
Use a disposable fake ship when developing or testing destructive actions.

## File transfers

**Upload…** accepts a single file or all files in a selected folder. Folder
contents go directly into the destination partial path; nested folders
become nested Clay paths. Filenames are lowercased, with characters outside
`a-z`, `0-9`, and `-` converted to `-`. Normalized-name collisions are refused.
The final extension selects the mark: `notes/readme.txt` becomes
`/notes/readme/txt`.

Replacing an existing file or installing missing marks requires consent.
Missing marks and their dependencies are copied from `%base` when available,
otherwise from Heathcliff's desk, in the same commit as the uploaded file.
Existing mark definitions are not replaced. Folder uploads commit one file
at a time; a failure stops the batch without undoing completed uploads.

**Download…** on a file saves its mark's external representation. On a desk
or partial path, it downloads the tree with subpaths preserved as local
folders. Current-tree downloads are pinned to one revision for consistency.
Direct folder downloads require a browser directory picker over HTTPS or
localhost. On ordinary HTTP or browsers without that picker, Heathcliff
automatically produces a ZIP instead. ZIP and RAR uploads are stored as
archives, not extracted.

## Delete and Tombstone

**Delete** applies to current files. Deleting a partial path preflights the
captured file list and commits all eligible deletions together in **one new
revision**. Files that fail preflight remain unchanged. No eligible files
means no new revision; a failed commit deletes none of its files. Earlier
revisions retain the deleted files, and affected open tabs keep their text
as unsaved drafts.

**Tombstone** applies only to prior revisions and permanently discards stored
content, not the historical path listing. Identical content may be shared
by other paths and revisions, which are affected too. Content still used
by any desk's current revision is protected. Tombstoning does not create a
revision and cannot be undone.

Partial-path operations warn about partial success and report per-file
failures. Tombstones are attempted individually. After a connection or
verification error, refresh the affected tree before retrying: the operation
may have reached the ship without confirmation.

## Limits and cautions

- Permissions are current-only; Clay does not keep historical rules.
  The kernel behavior targeted by Heathcliff stores and inherits write
  rules but does not enforce them. Do not treat a write rule as protection.
- Deleting a crew removes it from rules that name it. Removing a crew from
  a blacklist can broaden access. Explicit-rule discovery scans at most
  512 populated paths and cannot discover rules on empty paths.
- Uploads are limited to 8 MiB per file. Some marks cannot accept uploads;
  some binary marks reject trailing NUL bytes to prevent data loss. See
  the Users Guide for the mark-specific behavior.
- ZIP downloads are assembled in browser memory, without compression,
  with a 256 MiB archive limit and at most 65,534 files.
- Markdown previews accept up to 64 KiB. Media metadata inspection accepts
  up to 64 MiB and times out after 20 seconds. Media playback depends on
  the browser's format and codec support.

## Development and testing

The Gall boundary is in [`desk/app/heathcliff.hoon`](desk/app/heathcliff.hoon).
The main application libraries are:

- `heathcliff-web`: workbench layout, browser behavior, and previews.
- `heathcliff-clay`: desk discovery, revision paths, marks, and file views.
- `heathcliff-api` and `heathcliff-perm`: explorer requests, rules, and crews.
- `heathcliff-transfer` and `heathcliff-batch-delete`: verified transfers,
  tombstones, and single-commit recursive deletion.
- `heathcliff-markdown`: Markdown rendering and sanitization.

The HTTP routes are authenticated by the agent before data requests are
handled. The browser uses JSON requests for explorer and editing operations,
multipart uploads, and raw download routes; the route definitions and wire
formats live alongside their handlers.

Run the desk tests on a development ship after copying and committing changes:

```hoon
|commit %heathcliff
-test /=heathcliff=/tests ~
```

The local browser and Hoon checks use the sibling `../urui` checkout's
`vere eval` helpers and Playwright installation. With Node.js, a vere binary
supporting `eval`, Chromium installed for that Playwright version, and
`unzip` available, run from this repository:

```sh
node tests/previews.cjs
node tests/batch-delete-agent.cjs
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-batch-delete.hoon
```

Set `URUI_ROOT` for a different urui checkout when running the browser checks,
and `VERE` if the binary is not at `~/piers/urbit`. These checks compile real
desk sources without changing a ship. Browser tests use fixture responses;
backend tests exercise virtual Clay reads and verify emitted commit cards.
See [tests/README.md](tests/README.md) for the full commands and coverage.

Heathcliff's vendored urui sources include local adaptations. Review
[the urui change log](docs/urui-changes.md) before replacing shared files;
do not use urui's fixture-staging script to assemble this desk.
[Preview dependencies](docs/vendor.md) records the Markdown and MediaInfo
sources and inspection limits.

## Bug reports and contributions

Please open an issue with reproduction steps, the affected mark and revision,
browser details, whether the ship is served over HTTP or HTTPS, and any error
message. For file-transfer or preview problems, include a minimal sample
when possible, without private ship data. Documentation corrections and
contributions are welcome.

## License and credits

Copyright © 2026 Jack Fox. Heathcliff is licensed under the
[MIT License](LICENSE), with prior art by ~paldev and ~lagrev-nocfep.
Bundled dependencies retain their own licenses; see
[About](desk/doc/about.md) and [Preview dependencies](docs/vendor.md).
