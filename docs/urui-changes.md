# urui changes made for Heathcliff

Running log of every change to urui-owned files made during the Heathcliff
refactor, for the separate urui update project. Base: urui `e42e17b`.
Nothing here is committed in urui, graph-viz, or obelisk.

## Heathcliff reference attributes

Heathcliff's vendored `urui-js.hoon` now supports two optional consumer hooks:
`options.documents[store].label(tab)` supplies an exact tab label, bypassing
directory disambiguation; `options.refs[kind].dispose(ref)` releases resources
when a reference tab closes. Existing consumers retain the default behavior.
These hooks have not been propagated to the sibling urui checkout.

Historical editing adds `options.documents[store].beforeSave(tab, {path})`:
return `false` to cancel, or `{path, base}` to redirect a save with a conflict
token. Errors use the normal save failure path. The file policy adds
`edit-snapshots` (default false), enabled by Heathcliff to load editable text
copies. Writes and deletes to historical locations remain forbidden; only
the load path relaxes the editor's read-only flag. Codec inspection fallbacks
remain read-only.

`stored` now queries Clay's global `/tomb` endpoint at the bowl's current
time, while retaining the requested revision in the nested file beam.
Using the file revision on the outer, deskless endpoint caused `bail: 4`
when opening historical files. Virtual-scry regressions cover current and
historical text, historical tombstones, and read-only inspection.

## `%md` codec

`stock-codecs` maps `%md` to `%mime` (was `%cord`). `%base`'s md mark now
stores a `wain`, while desks served by %docs keep a `@t` md mark (%docs
reads `%cx` as `@t`; Heathcliff's switch to the `wain` mark broke
`/docs/d/heathcliff/*`). `%mime` converts through the mark on the file's own
desk, so either shape loads and saves. Heathcliff restored its `@t` md mark
and uses `[%md %mime]` in `heathcliff-clay` `codecs`.

## Files changed in `~/gitrepos/urui`

| File | Change |
| --- | --- |
| `desk/lib/urui-files.hoon` | `codec` gains `%mime`, `%view`; new `+$location`; `policy` gains `fallback`, `locate`, `view` (appended; `make-policy` sets `~`); new arms `resolve`, `encode`, `mime-read`, `mime-text`, `has-mark`, `tube-path`, failure `read-only` (403); `file-codec` admits any mark for `marks=~` and uses `fallback`; `stored` takes a location and returns `[text readonly]`, falling back to `view`; `load` replies `readonly: true`; save/delete refuse unwritable locations and `%view`; `change-cards` takes a location; `take` resolves the desk; `browse-paths` takes a location; `clay-beam` removed |
| `desk/lib/urui-js.hoon` | any-mark roots (`docRootOf`, file dialog); tab `readonly` from `load`, persisted, enforced (`docTabCanSave`); `options.contextMenu` items/state/select; `explorer.context.open(…, detail)`; `dialogs.modal`; `documents.previews.get`; `syncModalInert` leaves the body child containing the top modal (a consumer dialog's `div.app-dialogs` wrapper) un-inert |
| `desk/tests/lib/urui-files.hoon` | fixtures `clay-store`, `locate-desk`, `located`; 7 new arms |
| `tests/browser/scenarios/document-seams.js` | new doubles scenario for the seams above |
| `tests/browser/scenarios/index.js` | registers `document-seams` |
| `.agents/skills/urui-protocol/references/contracts.md` | documents the above; stock codecs list `mime` md |
| `desk/lib/urui-files.hoon` (md) | `stock-codecs`: `[%md %mime]` |
| `desk/tests/lib/urui-files.hoon` (md) | `test-file-codec` expects `%mime` for md |
| `tests/fixture/app/urui-fixture.hoon` | pre-existing bug: `++assets` bound a face `html`, shadowing zuse's `+html`, so `mimes:html` failed (`-find.mimes`) and `/tests/app/urui-fixture` never built; renamed to `page` |

## Propagation

- graph-viz, obelisk: `bin/sync.sh` (lib files and `.urui-sync.json`); no
  consumer code changes needed.
- heathcliff: `desk/lib/urui-files.hoon`, `desk/lib/urui-js.hoon`,
  `desk/tests/lib/urui-files.hoon` copied by hand.
- `%md` codec: copied by hand to heathcliff `desk/lib/urui-files.hoon` and
  `desk/tests/lib/urui-files.hoon`, and to the newcomet `%urui` and
  `%heathcliff` mounts. Not synced to graph-viz or obelisk.
- The `syncModalInert` fix to `urui-js.hoon` came after the consumer sync:
  graph-viz and obelisk are one change behind (`verify-sync` reports
  `desk/lib/urui-js.hoon` stale); heathcliff has it.

## Verification at the time

urui Hoon suites (files 32, js 15, shell 32, config 12 arms), doubles
(13 + 7 scenarios), Chromium 65 passed, purity ok; graph-viz Chromium 18
passed; obelisk-web lib compiles. Owner: `-test` on `%graph-viz`/`%obelisk`.
