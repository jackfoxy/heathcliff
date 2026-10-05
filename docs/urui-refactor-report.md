# Heathcliff on urui: report

Step 9.4 of `~/FoxyLabs/heathcliff/urui-refactor-plan.md`. Details are in
[urui-refactor-design.md](urui-refactor-design.md) and
[urui-changes.md](urui-changes.md); the user guide is
[desk/doc/users-guide.md](../desk/doc/users-guide.md).

## Changed files

| File | Change |
| --- | --- |
| `desk/app/heathcliff.hoon` | rewritten as a thin Gall boundary; state `%2` |
| `desk/lib/heathcliff-clay.hoon` | new: desks, titles, sorting, cases, `locate`, marks, inspection |
| `desk/lib/heathcliff-perm.hoon` | new: rules, explicit-rule scan, crews, their JSON |
| `desk/lib/heathcliff-transfer.hoon` | new: upload checks, verified commits, downloads |
| `desk/lib/heathcliff-api.hoon` | new: the JSON route |
| `desk/lib/heathcliff-web.hoon` | new: shell spec, config, file policy, css, app script |
| `desk/lib/urui-*.hoon`, `desk/sur/urui.hoon`, `desk/web/ace/` | urui sources (two libs changed, see urui-changes) |
| `desk/mar/hoon.hoon`, `desk/mar/md.hoon` | replaced by `%base`'s copies |
| `desk/desk.docket-0` | tile image and site moved off removed routes |
| `desk/doc/users-guide.md` | new |
| `desk/tests/lib/heathcliff-{clay,perm,transfer}.hoon`, `desk/tests/app/heathcliff.hoon` | new |
| `docs/` | design record, urui change log, this report |

## Per-mark policy

52 marks. Editable text: txt csv tab md pem (`wain`); hoon css js html svg
xml udon umd map (`cord`); json (`json`, invalid JSON refused); bill
docket-0 kelvin ship (through the mark's mime conversion). Everything else,
and any unknown mark, opens read-only with a summary, hex dump or printed
noun, and previews in the result pane. Full table: design record §1.

## Upload and download findings

- Upload was, and remains, Earth file → Clay directory. The visible Choose
  File control is gone; the hidden input remains for Upload….
- Old uploads and edits answered on dispatch; both now answer only after
  Clay reads the file back.
- The blanket trailing-NUL refusal is narrowed to atom marks; `mime`, `otf`,
  `ttf`, `woff2` keep every byte. Empty files are allowed when the mark
  converts them.
- Missing marks install, with opt-in, from `%base` first, else Heathcliff's
  `mar/`; existing marks are never replaced. Conversion is tried before
  the commit.
- Download already existed (`+down`); it is now `/heathcliff/raw/…` with a
  filename, the mark's MIME type, `attachment`, `nosniff`, and a sandbox
  CSP, at any revision.
- Clay write rules are not enforced (`may-write` has no callers at 408K);
  the dialog says so.

## Deleted code

The old page and its helpers, the five mode routes, and the favicon data
URI. Surviving logic moved into the libraries. List: design record §4. No
code of uncertain purpose remained.

## Verification

| Check | Result |
| --- | --- |
| `-test /=heathcliff=/tests ~` on a ship (owner) | all pass |
| urui Hoon suites, doubles, Chromium 65 cases, purity | pass |
| graph-viz Chromium suite | 18 passed |
| obelisk-web lib against new urui | compiles |
| Heathcliff page in Chromium with a mocked backend (local, not kept) | trees, Data scope, open, result, menu, dialog focus, upload, picker cancel, reload |
| Browser checks on a ship (9.2) | pending, owner |

Not verified anywhere yet: real Clay commits and read-backs through the
browser, tombstoned files, permission changes, and mark installs on a live
desk. These are in the 9.2 checklist.

## Open items

- graph-viz and obelisk are one `urui-js.hoon` change behind (the modal
  wrapper fix); sync them in the urui project.
- No questions open.
